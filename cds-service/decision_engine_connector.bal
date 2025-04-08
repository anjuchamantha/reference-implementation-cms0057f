import ballerinax/health.fhir.cds;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;

# ====================================== Please do your implementations to the below methods ===========================
#
# Consider the below steps while do your implementations.
#
# 1. Map the received CdsRequest/ Feedback request to the custom payload format, if needed (Optional).
# 2. Implement the connectivity with your external decision support systems.
# 3. Send the CdsRequest/ Feedback request to appropriate external systems.
# 4. Get the response.
# 5. Map the received response to the CdsCards and Cds actions.
# 6. Return the CdsResponse to the client.
#
# ======================================================================================================================

# Handle decision service connectivity.
#
# + cdsRequest - CdsRequest to sent to the backend.
# + hookId - ID of the hook being invoked.
# + return - return CdsResponse or CdsError
isolated function connectDecisionSystemForPrescribeMedication(cds:CdsRequest cdsRequest, string hookId) returns cds:CdsResponse|cds:CdsError {
    cds:OrderSignContext context = <cds:OrderSignContext>cdsRequest.context;
    string patientId = context.patientId;
    string coverageId = "";
    string medicationRequestId = "111112";

    match (patientId) {
        "101" => {
            coverageId = "367";
        }
        "102" => {
            coverageId = "480";
        }
        _ => {
            coverageId = "521";
        }
    }

    r4:BundleEntry[]? entry = context.draftOrders.entry;
    if entry is r4:BundleEntry[] {
        foreach var item in entry {
            r4:BundleEntry bundleEntry = item;
            r4:Resource|error result = parser:parse(bundleEntry?.'resource.toJson()).ensureType(r4:Resource);
            if result is r4:Resource {
                if (result.resourceType is "MedicationRequest") {
                    medicationRequestId = result.id is string ? <string>result.id : "111112";
                }
            }
        }
    }

    return {
        cards: [
            {
                "summary": "Prior Authorization Required",
                "indicator": "warning",
                "detail": "This medication (Aimovig) requires prior authorization from UnitedCare Health Insurance. Please complete the required documentation.",
                "source": {
                    "label": "UnitedCare Health Insurance ePA Service",
                    "url": "https://unitedcare.com/prior-auth"
                },
                "suggestions": [
                    {
                        "label": "Submit e-Prior Authorization",
                        "uuid": "submit-epa",
                        "actions": [
                            {
                                "type": "create",
                                "description": "Submit an electronic prior authorization request for Aimovig.",
                                "resource": {
                                    "resourceType": "Task",
                                    "status": "requested",
                                    "intent": "order",
                                    "code": {
                                        "coding": [
                                            {
                                                "system": "http://terminology.hl7.org/CodeSystem/task-code",
                                                "code": "prior-authorization",
                                                "display": "Submit Prior Authorization"
                                            }
                                        ]
                                    },
                                    "for": {
                                        "reference": string `Patient/${patientId}`
                                    },
                                    "owner": {
                                        "reference": "Organization/50"
                                    }
                                }
                            }
                        ]
                    }
                ],
                "links": [
                    {
                        "label": "Launch SMART App for DTR",
                        "url": string `${EHR_DTR_APP_LINK}?coverageId=${coverageId}&medicationRequestId=${medicationRequestId}&patientId=${patientId}`,
                        "type": "smart"
                    }
                ]
            }
        ]
    };
}

# Handle feedback service connectivity.
#
# + feedback - Feedback record to be processed.
# + hookId - ID of the hook being invoked.
# + return - return CdsError, if any.
isolated function connectFeedbackSystemForPrescribeMedication(cds:Feedbacks feedback, string hookId) returns cds:CdsError? {
    return cds:createCdsError(string `Rule repository backend not implemented/ connected yet for ${hookId}`, 501);
}

# Handle decision service connectivity.
#
# + cdsRequest - CdsRequest to sent to the backend.
# + hookId - ID of the hook being invoked.
# + return - return CdsResponse or CdsError
isolated function connectDecisionSystemForRadiology(cds:CdsRequest cdsRequest, string hookId) returns cds:CdsResponse|cds:CdsError {
    return cds:createCdsError(string `Rule repository backend not implemented/ connected yet for ${hookId}`, 501);
}

# Handle feedback service connectivity.
#
# + feedback - Feedback record to be processed.
# + hookId - ID of the hook being invoked.
# + return - return CdsError, if any.
isolated function connectFeedbackSystemForRadiology(cds:Feedbacks feedback, string hookId) returns cds:CdsError? {
    return cds:createCdsError(string `Rule repository backend not implemented/ connected yet for ${hookId}`, 501);
}

# Handle decision service connectivity.
#
# + cdsRequest - CdsRequest to sent to the backend.
# + hookId - ID of the hook being invoked.
# + return - return CdsResponse or CdsError
isolated function connectDecisionSystemForRadiologyOrder(cds:CdsRequest cdsRequest, string hookId) returns cds:CdsResponse|cds:CdsError {
    return cds:createCdsError(string `Rule repository backend not implemented/ connected yet for ${hookId}`, 501);
}

# Handle feedback service connectivity.
#
# + feedback - Feedback record to be processed.
# + hookId - ID of the hook being invoked.
# + return - return CdsError, if any.
isolated function connectFeedbackSystemForRadiologyOrder(cds:Feedbacks feedback, string hookId) returns cds:CdsError? {
    return cds:createCdsError(string `Rule repository backend not implemented/ connected yet for ${hookId}`, 501);
}
