public class CVMS_AccountDeletionIntegrationService {
    @future(callout = true)
    public static void sendAccountDeletionToCVMS(Set<String> deletedAccountIds) {
        if (deletedAccountIds == null || deletedAccountIds.isEmpty()) return;

        Set<String> uniqueIds = new Set<String>(deletedAccountIds);
        List<AccountDeletionRequest> requestList = new List<AccountDeletionRequest>();

        for (String accId : uniqueIds) {
            requestList.add(new AccountDeletionRequest(accId));
        }

        system.debug('requestList==>'+requestList);
        
        String requestBody = JSON.serialize(requestList);
        system.debug('requestBody==>'+requestBody);
        String responseBody = '';
        String errorMsg = '';
        String status = 'Failed';
        Decimal statusCode;

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:CVMS_Named_CSF/Services/api/salesforce/account/remove');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(requestBody);

        List<DB_Log_Summary__c> logsToInsert = new List<DB_Log_Summary__c>();

        try {
            HttpResponse res = http.send(req);
            responseBody = res.getBody();
            statusCode = res.getStatusCode();
            System.debug('Response Body: ' + responseBody);
            System.debug('Status Code: ' + statusCode);

            if (statusCode == 200) {
                List<AccountDeletionResponse> responseList =
                    (List<AccountDeletionResponse>) JSON.deserialize(responseBody, List<AccountDeletionResponse>.class);
                updateBlockedAccountsWithIntegrationStatus(responseList, logsToInsert);
                status = 'Success';
            } else {
                errorMsg = 'Non-200 response: ' + statusCode;
            }
        } catch (Exception ex) {
            errorMsg = ex.getMessage();
        }

        // Add log for API request/response
        logsToInsert.add(new DB_Log_Summary__c(
          
            Status__c = status,
            Error__c = errorMsg,
            Response__c = 'Status Code: ' + String.valueOf(statusCode) + ' | Response Body: ' + responseBody,
            Request__c = requestBody
        ));

        // Final log insert
        if (!logsToInsert.isEmpty()) {
            try {
                insert logsToInsert;
            } catch (Exception logEx) {
                System.debug('Failed to insert DB_Log_Summary__c: ' + logEx.getMessage());
            }
        }
    }

    public static void updateBlockedAccountsWithIntegrationStatus(
        List<AccountDeletionResponse> responseList,
        List<DB_Log_Summary__c> logsToInsert
    ) {
        if (responseList == null || responseList.isEmpty()) return;

        List<Blocked_Account__c> toUpsert = new List<Blocked_Account__c>();

        for (AccountDeletionResponse resp : responseList) {
            Blocked_Account__c ba = new Blocked_Account__c();
            ba.Deleted_Account_ID__c = resp.AccountId;
            ba.CVMS_Status__c = resp.Status;
            ba.CVMS_Error_Message__c = resp.errorMessage;
            ba.Deleted_in_CVMS__c = resp.Status == 'Success';
            toUpsert.add(ba);
        }

        if (!toUpsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(toUpsert, Blocked_Account__c.Deleted_Account_ID__c, false);

                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        logsToInsert.add(new DB_Log_Summary__c(
                            
                            Status__c = 'Upsert Failed',
                            Error__c = results[i].getErrors()[0].getMessage(),
                            Request__c = 'AccountId: ' + toUpsert[i].Deleted_Account_ID__c,
                            Response__c = 'CVMS_Status: ' + toUpsert[i].CVMS_Status__c +
                                          ' | CVMS_Error: ' + toUpsert[i].CVMS_Error_Message__c
                        ));
                    }
                }
            } catch (Exception ex) {
                logsToInsert.add(new DB_Log_Summary__c(
                    
                    Status__c = 'Exception',
                    Error__c = ex.getMessage(),
                    Request__c = JSON.serialize(toUpsert),
                    Response__c = ''
                ));
            }
        }
    }

    // Wrapper class for request
    public class AccountDeletionRequest {
        public String AccountId;
        public AccountDeletionRequest(String accountId) {
            this.AccountId = accountId;
        }
    }

    // Wrapper class for response
    public class AccountDeletionResponse {
        public String accountId;
        public String status;
        public String errorMessage;
    }
}