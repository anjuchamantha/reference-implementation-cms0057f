import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreConditionEncounterDiagnosisProfile[] conditions = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreConditionEncounterDiagnosisProfile {
    uscore700:USCoreConditionEncounterDiagnosisProfile|error condition = parser:parse(payload, uscore700:USCoreConditionEncounterDiagnosisProfile).ensureType();

    if condition is error {
        return r4:createFHIRError(condition.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            condition.id = (createOperationNextId).toBalString();
        }

        lock {
            conditions.push(condition.clone());
        }

        return condition;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreConditionEncounterDiagnosisProfile {
    lock {
        foreach var item in conditions {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a condition resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreConditionEncounterDiagnosisProfile byId = check getById(searchParameters.get('key)[0]);
                    bundle.entry = [
                        {
                            'resource: byId
                        }
                    ];
                    return bundle;
                }
                _ => {
                    return r4:createFHIRError(string `Not supported search parameter: ${'key}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
                }
            }
        }
    }

    lock {
        r4:BundleEntry[] bundleEntries = [];
        foreach var item in conditions {
            r4:BundleEntry bundleEntry = {
                'resource: item
            };
            bundleEntries.push(bundleEntry);
        }
        r4:Bundle cloneBundle = bundle.clone();
        cloneBundle.entry = bundleEntries;
        return cloneBundle.clone();
    }
}

function init() returns error? {
    lock {
        json conditionJson = {
            "resourceType": "Condition",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition-encounter-diagnosis"]
            },
            "text": {
                "status": "extensions",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: Condition</b><a name=\"encounter-diagnosis-example1\"> </a><a name=\"hcencounter-diagnosis-example1\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource Condition &quot;encounter-diagnosis-example1&quot; </p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-us-core-condition-encounter-diagnosis.html\">US Core Condition Encounter Diagnosis Profile (version 7.0.0)</a></p></div><p><b>Condition Asserted Date</b>: 2015-10-31</p><p><b>clinicalStatus</b>: Resolved <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.5.0/CodeSystem-condition-clinical.html\">Condition Clinical Status Codes</a>#resolved)</span></p><p><b>verificationStatus</b>: Confirmed <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.5.0/CodeSystem-condition-ver-status.html\">ConditionVerificationStatus</a>#confirmed)</span></p><p><b>category</b>: Encounter Diagnosis <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.5.0/CodeSystem-condition-category.html\">Condition Category Codes</a>#encounter-diagnosis)</span></p><p><b>code</b>: Burnt Ear <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"https://browser.ihtsdotools.org/\">SNOMED CT[US]</a>#39065001 &quot;Burn of ear&quot;)</span></p><p><b>subject</b>: <a href=\"Patient-example.html\">Patient/example: Amy Shaw</a> &quot; SHAW&quot;</p><p><b>encounter</b>: <a href=\"Encounter-example-1.html\">Encounter/example-1</a></p><p><b>onset</b>: 2015-10-31</p><p><b>abatement</b>: 2015-12-01</p><p><b>recordedDate</b>: 2015-11-01</p></div>"
            },
            "extension": [
                {
                    "url": "http://hl7.org/fhir/StructureDefinition/condition-assertedDate",
                    "valueDateTime": "2015-10-31"
                }
            ],
            "clinicalStatus": {
                "coding": [
                    {
                        "system": "http://terminology.hl7.org/CodeSystem/condition-clinical",
                        "code": "resolved"
                    }
                ]
            },
            "verificationStatus": {
                "coding": [
                    {
                        "system": "http://terminology.hl7.org/CodeSystem/condition-ver-status",
                        "code": "confirmed"
                    }
                ]
            },
            "category": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/condition-category",
                            "code": "encounter-diagnosis",
                            "display": "Encounter Diagnosis"
                        }
                    ]
                }
            ],
            "code": {
                "coding": [
                    {
                        "system": "http://snomed.info/sct",
                        "version": "http://snomed.info/sct/731000124108",
                        "code": "39065001",
                        "display": "Burn of ear"
                    }
                ],
                "text": "Burnt Ear"
            },
            "subject": {
                "reference": "Patient/example",
                "display": "Amy Shaw"
            },
            "encounter": {
                "reference": "Encounter/example-1"
            },
            "onsetDateTime": "2015-10-31",
            "abatementDateTime": "2015-12-01",
            "recordedDate": "2015-11-01"
        };

        uscore700:USCoreConditionEncounterDiagnosisProfile condition = check parser:parseWithValidation(conditionJson, uscore700:USCoreConditionEncounterDiagnosisProfile).ensureType();
        conditions.push(condition.clone());
    }
}
