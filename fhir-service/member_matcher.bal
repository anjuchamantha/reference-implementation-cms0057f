// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;
import ballerinax/health.clients.fhir as fhirClient;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincihrex100 as hrex100;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.uscore501;

// Error indicating an internal server error occurred during the member matching process
final r4:FHIRError & readonly INTERNAL_ERROR = r4:createFHIRError("Internal server error", r4:ERROR,
        r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);

configurable string CONSENT_SERVICE_BASE_URL = "http://localhost:9090";
configurable boolean ENABLE_MEMBER_MATCH_CONSENT_PERSISTENCE = false;

# # This class implements the reference member matcher for the Da Vinci HRex Member Matcher.
# # The matcher is used to match a member's coverage with the existing patient records in the FHIR repository.
# # It uses the patient's name and coverage details to find a match in the existing patient records.
# # If a match is found, it returns the member identifier (patient ID). If no match is found, it returns an error indicating that no match was found.
public isolated class DemoFHIRMemberMatcher {
    *hrex100:MemberMatcher;
    private final fhirClient:FHIRConnector fhirConnector;

    public isolated function init(fhirClient:FHIRConnector fhirConnector) {
        self.fhirConnector = fhirConnector;
    }

    public isolated function matchMember(anydata memberMatchResources) returns hrex100:MemberIdentifier|r4:FHIRError {

        if memberMatchResources !is hrex100:MemberMatchResources {
            log:printError("Invalid type for \"memberMatchResources\". Expected type: MemberMatchResources.");
            return r4:createFHIRError("Internal server error", r4:ERROR, r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
        log:printDebug("Custom matcher engaged");

        // Member match resources
        uscore501:USCorePatientProfile memberPatient = memberMatchResources.memberPatient;
        hrex100:HRexConsent? consent = memberMatchResources.consent;
        hrex100:HRexCoverage coverageToMatch = memberMatchResources.coverageToMatch;
        hrex100:HRexCoverage? _ = memberMatchResources.coverageToLink;

        // Get patient resource from OLD payor
        // Search Patient from given name
        uscore501:USCorePatientProfileName[] name = memberPatient.name;
        if name.length() == 0 {
            return r4:createFHIRError("No patient name found", r4:ERROR, r4:INVALID_REQUIRED,
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }

        string[] given = name[0].given ?: [];
        if given.length() == 0 {
            return r4:createFHIRError("No patient given name found", r4:ERROR, r4:INVALID_REQUIRED,
                    httpStatusCode = http:STATUS_BAD_REQUEST);
        }
        r4:Bundle nameMatchedPatients = check search(self.fhirConnector, PATIENT, {"given": [given[0]]});

        r4:BundleEntry[]? entry = nameMatchedPatients.entry;

        if entry is r4:BundleEntry[] {
            if entry.length() == 0 {
                return r4:createFHIRError("No match found", r4:ERROR, r4:PROCESSING_NOT_FOUND,
                        httpStatusCode = http:STATUS_UNPROCESSABLE_ENTITY);
            }
            r4:BundleEntry firstEntry = entry[0];

            anydata 'resource = firstEntry?.'resource;

            international401:Patient|error cloneWithType = 'resource.cloneWithType(international401:Patient);
            international401:Patient oldPatient = {};
            if cloneWithType is international401:Patient {
                oldPatient = self.filterPatientsByDemographics([cloneWithType], memberPatient.clone());
            }
            if oldPatient.id !is string {
                log:printError("Matched patient is missing id");
                return INTERNAL_ERROR;
            }
            string patientId = <string>oldPatient.id;

            // Get coverage from id
            if coverageToMatch.id !is string {
                log:printError("Incoming coverage is missing id");
                return INTERNAL_ERROR;
            }
            string coverageId = <string>coverageToMatch.id;
            r4:DomainResource|r4:FHIRError oldCoverage = check getById(self.fhirConnector, COVERAGE, coverageId);

            if oldCoverage is r4:FHIRError {
                log:printError("FHIR read response is not a valid FHIR Resource", oldCoverage);
                return INTERNAL_ERROR;
            }
            international401:Coverage|error i4OldCoverage = oldCoverage.cloneWithType();
            if i4OldCoverage is error {
                log:printError("Failed to clone old coverage resource", i4OldCoverage);
                return INTERNAL_ERROR;
            }
            string oldBeneficiaryRef = <string>i4OldCoverage.beneficiary.reference;
            if !oldBeneficiaryRef.startsWith("Patient/") {
                log:printError(string `Unexpected beneficiary reference format: ${oldBeneficiaryRef}`);
                return INTERNAL_ERROR;
            }

            // string substring = oldBeneficiaryRef.substring(8);

            // if substring != incomingCoverageBeneficiary.reference {
            //     log:printError(string `Beneficiaries Mismatch. Old reference:${oldBeneficiaryRef}  Patient ID:${patientId}`);
            //     //verify with incoming beneficiary reference
            //     return INTERNAL_ERROR;
            // }

            // If both beneficiaryRef and oldPatient.id are same, we can derive it as a match
            if oldBeneficiaryRef.substring(8) == patientId {
                //match found

                if ENABLE_MEMBER_MATCH_CONSENT_PERSISTENCE {
                    if consent is () {
                        return r4:createFHIRError("Consent is required for member match",
                                r4:ERROR, r4:INVALID_REQUIRED,
                                httpStatusCode = http:STATUS_BAD_REQUEST);
                    }

                    hrex100:HRexConsent|r4:FHIRError persistedConsent = self.persistConsent(consent, patientId);
                    if persistedConsent is r4:FHIRError {
                        return persistedConsent;
                    }
                }

                return <hrex100:MemberIdentifier>patientId;
            }

            return r4:createFHIRError("No match found", r4:ERROR, r4:PROCESSING_NOT_FOUND, httpStatusCode = http:STATUS_UNPROCESSABLE_ENTITY);
        }
        return r4:createFHIRError("No match found", r4:ERROR, r4:PROCESSING_NOT_FOUND, httpStatusCode = http:STATUS_UNPROCESSABLE_ENTITY);
    }

    private isolated function filterPatientsByDemographics(international401:Patient[] nameMatchedPatients, uscore501:USCorePatientProfile memberPatient)
    returns international401:Patient {
        international401:Patient filteredPatient = {};
        uscore501:USCorePatientProfileGender incomingPatientGender = memberPatient.gender;
        r4:date? birthDate = memberPatient.birthDate;

        log:printDebug(string `Demographic values from the request: Gender = ${incomingPatientGender} , DoB = ${birthDate.toBalString()}`);

        // Additional filter logic can be added here.
        // foreach international401:Patient patient in nameMatchedPatients {

        // }

        // Selecting the first element as the matched patient for the reference Impl
        filteredPatient = nameMatchedPatients[0];

        return filteredPatient;
    }

    private isolated function getNameMatchedPatients(fhirClient:FHIRConnector fhirConnector, uscore501:USCorePatientProfileName[] name) returns international401:Patient[]|r4:FHIRError & readonly {

        international401:Patient[] nameMatchedPatients = [];
        string[] givenNames = [];

        foreach uscore501:USCorePatientProfileName patientName in name {
            if patientName.given is string[] {
                if (<string[]>patientName.given).length() > 0 {
                    foreach string givenName in <string[]>patientName.given {
                        givenNames[givenNames.length()] = givenName;
                    }
                }

            }
        }

        foreach string givenName in givenNames {
            map<string[]> searchParams = {};
            searchParams["given"] = [givenName];
            // fhir:FHIRResponse|fhir:FHIRError searchRes = self.search("Patient", searchParams, ());
            // if searchRes is fhir:FHIRError {
            //     log:printError("FHIR search error", searchRes);
            //     return INTERNAL_ERROR;
            // }
            // r4:Bundle|error searchBundle = searchRes.'resource.cloneWithType();
            r4:FHIRError|r4:Bundle searchBundle = search(fhirConnector, PATIENT, searchParams);
            if searchBundle is error {
                log:printError("FHIR search response is not a valid FHIR Bundle", searchBundle);
                return INTERNAL_ERROR;
            }
            r4:BundleEntry[]? patientBundleEntries = searchBundle.entry;
            if patientBundleEntries == () || patientBundleEntries.length() == 0 { // No matches
                continue;
            }

            foreach r4:BundleEntry bundleEntry in patientBundleEntries {
                international401:Patient|error matchedPatient = bundleEntry?.'resource.cloneWithType();
                if matchedPatient is international401:Patient {
                    nameMatchedPatients.push(matchedPatient);
                } else {
                    log:printError("Matched patient resource is not a valid US Core patient resource", matchedPatient);
                }
            }
        }

        return nameMatchedPatients;

    }

    isolated function persistConsent(hrex100:HRexConsent consentResource, string memberIdentifier) returns hrex100:HRexConsent|r4:FHIRError {
        http:Client|error consentClient = new (CONSENT_SERVICE_BASE_URL);

        if consentClient is error {
            log:printError("Failed to create consent client", consentClient);
            return r4:createFHIRError("Internal server error - failed to create client",
                    r4:ERROR, r4:PROCESSING,
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }

        hrex100:HRexConsent consentToSave = consentResource.clone();
        consentToSave.patient = {
            reference: string `Patient/${memberIdentifier}`
        };

        http:Response|error response = consentClient->post("/fhir/r4/Consent", consentToSave.toJson(), {
            "Content-Type": "application/fhir+json",
            "Accept": "application/fhir+json"
        });

        if response is error {
            log:printError("Failed to persist consent resource", response);
            return r4:createFHIRError("Internal server error - failed to persist consent",
                    r4:ERROR, r4:PROCESSING,
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }

        int statusCode = response.statusCode;
        if statusCode != http:STATUS_OK && statusCode != http:STATUS_CREATED {
            log:printError(string `Consent persistence failed with status: ${statusCode}`);
            return r4:createFHIRError("Failed to persist consent resource",
                    r4:ERROR, r4:PROCESSING,
                    httpStatusCode = statusCode);
        }

        json|error responsePayload = response.getJsonPayload();
        if responsePayload is error {
            log:printError("Failed to parse persisted consent response payload", responsePayload);
            return r4:createFHIRError("Invalid persisted consent response format",
                    r4:ERROR, r4:PROCESSING,
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }

        hrex100:HRexConsent|error persistedConsent = responsePayload.cloneWithType();
        if persistedConsent is error {
            log:printError("Failed to convert persisted consent response", persistedConsent);
            return r4:createFHIRError("Invalid persisted consent response",
                    r4:ERROR, r4:PROCESSING,
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }

        return persistedConsent;
    }
}
