import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreEncounterProfile[] encounters = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreEncounterProfile {
    uscore700:USCoreEncounterProfile|error encounter = parser:parse(payload, uscore700:USCoreEncounterProfile).ensureType();

    if encounter is error {
        return r4:createFHIRError(encounter.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            encounter.id = (createOperationNextId).toBalString();
        }

        lock {
            encounters.push(encounter.clone());
        }

        return encounter;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreEncounterProfile {
    lock {
        foreach var item in encounters {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a encounter resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreEncounterProfile byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in encounters {
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
        json encounterJson = {
            "resourceType": "Encounter",
            "id": "12344",
            "meta": {
                "lastUpdated": "2024-01-28T16:06:21-08:00",
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter|7.0.0"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: Encounter</b><a name=\"1036\"> </a><a name=\"hc1036\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource Encounter &quot;1036&quot; Updated &quot;2024-01-28 16:06:21-0800&quot; </p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-us-core-encounter.html\">US Core Encounter Profile (version 7.0.0)</a></p></div><p><b>status</b>: in-progress</p><p><b>class</b>: inpatient encounter (Details: http://terminology.hl7.org/CodeSystem/v3-ActCode code IMP = 'inpatient encounter', stated as 'inpatient encounter')</p><p><b>type</b>: Unknown (qualifier value) <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"https://browser.ihtsdotools.org/\">SNOMED CT[US]</a>#261665006)</span></p><p><b>subject</b>: <a href=\"Patient-example.html\">Patient/example</a> &quot; SHAW&quot;</p><h3>Hospitalizations</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>DischargeDisposition</b></td></tr><tr><td style=\"display: none\">*</td><td>Discharged to Home <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.3.0/CodeSystem-AHANUBCPatientDischargeStatus.html\">AHA NUBC Patient Discharge Status Codes</a>#01)</span></td></tr></table><h3>Locations</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>Location</b></td></tr><tr><td style=\"display: none\">*</td><td><a href=\"Location-hospital.html\">Location/hospital: Holy Family Hospital</a> &quot;Holy Family Hospital&quot;</td></tr></table></div>"
            },
            "status": "in-progress",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "IMP",
                "display": "inpatient encounter"
            },
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://snomed.info/sct",
                            "version": "http://snomed.info/sct/731000124108",
                            "code": "261665006",
                            "display": "Unknown (qualifier value)"
                        }
                    ],
                    "text": "Unknown (qualifier value)"
                }
            ],
            "subject": {
                "reference": "Patient/example"
            },
            "hospitalization": {
                "dischargeDisposition": {
                    "coding": [
                        {
                            "system": "https://www.nubc.org/CodeSystem/PatDischargeStatus",
                            "code": "01",
                            "display": "Discharged to Home"
                        }
                    ]
                }
            },
            "location": [
                {
                    "location": {
                        "reference": "Location/hospital",
                        "display": "Holy Family Hospital"
                    }
                }
            ]
        };
        uscore700:USCoreEncounterProfile encounter = check parser:parse(encounterJson, uscore700:USCoreEncounterProfile).ensureType();
        encounters.push(encounter.clone());
    }
}
