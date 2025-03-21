import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreOrganizationProfile[] organizations = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreOrganizationProfile {
    uscore700:USCoreOrganizationProfile|error organization = parser:parse(payload, uscore700:USCoreOrganizationProfile).ensureType();

    if organization is error {
        return r4:createFHIRError(organization.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            organization.id = (createOperationNextId).toBalString();
        }

        lock {
            organizations.push(organization.clone());
        }

        return organization;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreOrganizationProfile {
    lock {
        foreach var item in organizations {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a organization resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreOrganizationProfile byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in organizations {
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
        json organizationJson = {
            "resourceType": "Organization",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization|7.0.0"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: Organization</b><a name=\"acme-lab\"> </a><a name=\"hcacme-lab\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource Organization &quot;acme-lab&quot; </p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-us-core-organization.html\">US Core Organization Profile (version 7.0.0)</a></p></div><p><b>identifier</b>: <a href=\"http://terminology.hl7.org/5.3.0/NamingSystem-npi.html\" title=\"National Provider Identifier\">United States National Provider Identifier</a>/1144221847, <a href=\"http://terminology.hl7.org/5.3.0/NamingSystem-CLIA.html\" title=\"&quot;The Centers for Medicare &amp; Medicaid Services (CMS) regulates all laboratory testing (except research) performed on humans in the U.S. through the Clinical Laboratory Improvement Amendments (CLIA). In total, CLIA covers approximately 330,000 laboratory entities. The Division of Clinical Laboratory Improvement &amp; Quality, within the Quality, Safety &amp; Oversight Group, under the Center for Clinical Standards and Quality (CCSQ) has the responsibility for implementing the CLIA Program.\r\n\r\nThe objective of the CLIA program is to ensure quality laboratory testing. Although all clinical laboratories must be properly certified to receive Medicare or Medicaid payments, CLIA has no direct Medicare or Medicaid program responsibilities.&quot;\r\n\r\nCMS CLIA certified laboratories will be assigned a10-digit alphanumeric CLIA identification number, with the &quot;D&quot; in the third position identifying the provider/supplier as a laboratory certified under CLIA.&quot;\r\n\r\nCLIA is maintained by CMS. It is in the public domain and free to use without restriction.\r\n\r\nSee http://cms.gov/regulations-and-guidance/legislation/clia.\">Clinical Laboratory Improvement Amendments</a>/12D4567890</p><p><b>active</b>: true</p><p><b>type</b>: Healthcare Provider <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.5.0/CodeSystem-organization-type.html\">Organization type</a>#prov)</span></p><p><b>name</b>: Acme Labs</p><p><b>telecom</b>: ph: (+1) 734-677-7777, <a href=\"mailto:hq@acme.org\">hq@acme.org</a></p><p><b>address</b>: 3300 WASHTENAW AVE STE 227 AMHERST MA 01002 USA </p></div>"
            },
            "identifier": [
                {
                    "system": "http://hl7.org/fhir/sid/us-npi",
                    "value": "1144221847"
                },
                {
                    "system": "urn:oid:2.16.840.1.113883.4.7",
                    "value": "12D4567890"
                }
            ],
            "active": true,
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/organization-type",
                            "code": "prov",
                            "display": "Healthcare Provider"
                        }
                    ]
                }
            ],
            "name": "Acme Labs",
            "telecom": [
                {
                    "system": "phone",
                    "value": "(+1) 734-677-7777"
                },
                {
                    "system": "email",
                    "value": "hq@acme.org"
                }
            ],
            "address": [
                {
                    "line": ["3300 WASHTENAW AVE STE 227"],
                    "city": "AMHERST",
                    "state": "MA",
                    "postalCode": "01002",
                    "country": "USA"
                }
            ]
        };
        uscore700:USCoreOrganizationProfile organization = check parser:parse(organizationJson, uscore700:USCoreOrganizationProfile).ensureType();
        organizations.push(organization.clone());
    }
}
