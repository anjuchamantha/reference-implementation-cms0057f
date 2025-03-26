import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCorePatientProfile[] patients = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCorePatientProfile {
    uscore700:USCorePatientProfile|error patient = parser:parse(payload, uscore700:USCorePatientProfile).ensureType();

    if patient is error {
        return r4:createFHIRError(patient.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            patient.id = (createOperationNextId).toBalString();
        }

        lock {
            patients.push(patient.clone());
        }

        return patient;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCorePatientProfile {
    lock {
        foreach var item in patients {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a patient resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCorePatientProfile byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in patients {
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
        json patientJson = {
            "resourceType": "Patient",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient|7.0.0"]
            },
            "text": {
                "status": "generated",
                "div": string `<div xmlns="http://www.w3.org/1999/xhtml"><p style="border: 1px #661aff solid; background-color: #e6e6ff; padding: 10px;"><b>Child Example </b> male, DoB: 2016-01-15 ( Medical Record Number/1032704\u00a0(use:\u00a0usual))</p><hr/><table class="grid"><tr><td style="background-color: #f3f5da" title="Record is active">Active:</td><td colspan="3">true</td></tr><tr><td style="background-color: #f3f5da" title="Ways to contact the Patient">Contact Detail</td><td colspan="3"><ul><li>ph: 555-555-5555(HOME)</li><li>49 MEADOW ST MOUNDS OK 74047 US </li></ul></td></tr><tr><td style="background-color: #f3f5da" title="The Sex Extension is used to reflect the documentation of a person's sex. Systems choosing to record sources of information should use the [Provenance resource](basic-provenance.html#element-level-provenance).\n \nUSCDI includes a data element for sex, intended to support the exchange of a sex value that is not characterized as sex assigned at birth or birth sex. This Sex extension supports USCDI. Sex assigned at birth or birth sex can be recorded using the more specific [US Core Birth Sex Extension](StructureDefinition-us-core-birthsex.html).\nFuture versions of this extension may be informed by the content of the HL7 Cross Paradigm IG: Gender Harmony - Sex and Gender Representation, which may include additional guidance on its relationship to administrative gender ([Patient.gender](StructureDefinition-us-core-patient-definitions.html#Patient.gender))."><a href="StructureDefinition-us-core-sex.html">US Core Sex Extension</a></td><td colspan="3"><ul><li>248153007</li></ul></td></tr><tr><td style="background-color: #f3f5da" title="Concepts classifying the person into a named category of humans sharing common history, traits, geographical origin or nationality.  The ethnicity codes used to represent these concepts are based upon the [CDC ethnicity and Ethnicity Code Set Version 1.0](http://www.cdc.gov/phin/resources/vocabulary/index.html) which includes over 900 concepts for representing race and ethnicity of which 43 reference ethnicity.  The ethnicity concepts are grouped by and pre-mapped to the 2 OMB ethnicity categories: - Hispanic or Latino - Not Hispanic or Latino.">US Core Ethnicity Extension:</td><td colspan="3"><ul><li>ombCategory: <a href="https://phinvads.cdc.gov/vads/ViewCodeSystem.action?id=2.16.840.1.113883.6.238#CDCREC-2186-5">CDC Race and Ethnicity</a> 2186-5: Not Hispanic or Latino</li><li>text: Not Hispanic or Latino</li></ul></td></tr><tr><td style="background-color: #f3f5da" title="A code classifying the person's sex assigned at birth  as specified by the [Office of the National Coordinator for Health IT (ONC)](https://www.healthit.gov/newsroom/about-onc). This extension aligns with the C-CDA Birth Sex Observation (LOINC 76689-9). After version 6.0.0, this extension is no longer a *USCDI Requirement*."><a href="StructureDefinition-us-core-birthsex.html">US Core Birth Sex Extension</a></td><td colspan="3"><ul><li>M</li></ul></td></tr><tr><td style="background-color: #f3f5da" title="Concepts classifying the person into a named category of humans sharing common history, traits, geographical origin or nationality.  The race codes used to represent these concepts are based upon the [CDC Race and Ethnicity Code Set Version 1.0](http://www.cdc.gov/phin/resources/vocabulary/index.html#3) which includes over 900 concepts for representing race and ethnicity of which 921 reference race.  The race concepts are grouped by and pre-mapped to the 5 OMB race categories:\n\n - American Indian or Alaska Native\n - Asian\n - Black or African American\n - Native Hawaiian or Other Pacific Islander\n - White.">US Core Race Extension:</td><td colspan="3"><ul><li>ombCategory: <a href="https://phinvads.cdc.gov/vads/ViewCodeSystem.action?id=2.16.840.1.113883.6.238#CDCREC-2028-9">CDC Race and Ethnicity</a> 2028-9: Asian</li><li>text: Asian</li></ul></td></tr></table></div>`
            },
            "extension": [
                {
                    "extension": [
                        {
                            "url": "ombCategory",
                            "valueCoding": {
                                "system": "urn:oid:2.16.840.1.113883.6.238",
                                "code": "2028-9",
                                "display": "Asian"
                            }
                        },
                        {
                            "url": "text",
                            "valueString": "Asian"
                        }
                    ],
                    "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race"
                },
                {
                    "extension": [
                        {
                            "url": "ombCategory",
                            "valueCoding": {
                                "system": "urn:oid:2.16.840.1.113883.6.238",
                                "code": "2186-5",
                                "display": "Not Hispanic or Latino"
                            }
                        },
                        {
                            "url": "text",
                            "valueString": "Not Hispanic or Latino"
                        }
                    ],
                    "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity"
                },
                {
                    "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
                    "valueCode": "M"
                },
                {
                    "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-sex",
                    "valueCode": "248153007"
                }
            ],
            "identifier": [
                {
                    "use": "usual",
                    "type": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/v2-0203",
                                "code": "MR",
                                "display": "Medical Record Number"
                            }
                        ],
                        "text": "Medical Record Number"
                    },
                    "system": "http://hospital.smarthealthit.org",
                    "value": "1032704"
                }
            ],
            "active": true,
            "name": [
                {
                    "family": "Example",
                    "given": ["Child"]
                }
            ],
            "telecom": [
                {
                    "system": "phone",
                    "value": "555-555-5555",
                    "use": "home"
                }
            ],
            "gender": "male",
            "birthDate": "2016-01-15",
            "address": [
                {
                    "line": ["49 MEADOW ST"],
                    "city": "MOUNDS",
                    "state": "OK",
                    "postalCode": "74047",
                    "country": "US"
                }
            ]
        };
        uscore700:USCorePatientProfile patient = check parser:parse(patientJson, uscore700:USCorePatientProfile).ensureType();
        patients.push(patient.clone());
    }
}
