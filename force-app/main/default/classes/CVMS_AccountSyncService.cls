public with sharing class CVMS_AccountSyncService {
    
    //private static final String CVMS_ENDPOINT = 'https://api/salesforce/account/set'; 
    
    public static void sendAccountsToCVMS(List<Account> accountList) {
        if (accountList.isEmpty()) return;
        
        List<Account> accountsToUpdate = new List<Account>();
        List<DB_Log_Summary__c> errorLogs = new List<DB_Log_Summary__c>();
        
        try {
            HttpRequest req = new HttpRequest();
            //req.setEndpoint(CVMS_ENDPOINT);
            req.setEndpoint('callout:CVMS_Named_CSF/Services/api/salesforce/accounts/upsert');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            
            
            /*CVMS_AccountWrapper.Request requestBody = new CVMS_AccountWrapper.Request(accountList);
req.setBody(JSON.serialize(requestBody));*/
            
            List<CVMS_AccountWrapper.AccountData> requestBody = new List<CVMS_AccountWrapper.AccountData>();
            for (Account acc : accountList) {
                requestBody.add(new CVMS_AccountWrapper.AccountData(acc));
            }
            req.setBody(JSON.serialize(requestBody));
            
            System.debug('requestBody: ' +requestBody); 
            System.debug('requestBody: ' +JSON.serialize(requestBody)); 
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('res.getStatusCode(): ' + res.getStatusCode()); 
            System.debug('res.getBody(): ' + res.getBody()); 
            if (res.getStatusCode() == 200) {
                /* CVMS_AccountWrapper.Response responseBody = 
(CVMS_AccountWrapper.Response) JSON.deserialize(res.getBody(), CVMS_AccountWrapper.Response.class);*/
                List<CVMS_AccountWrapper.ResponseData> responseList =
                    (List<CVMS_AccountWrapper.ResponseData>) JSON.deserialize(res.getBody(), List<CVMS_AccountWrapper.ResponseData>.class);
                
                
                
                for (CVMS_AccountWrapper.ResponseData response : responseList) {
                    Boolean isSuccess = (response.statusCode == '200' && response.status != 'Failure');
                    
                    if (isSuccess) {
                        accountsToUpdate.add(new Account(
                            Id = response.sfAccountId,
                            Integrated_with_CVMS__c = true
                        ));
                    } else {
                        if (response.ErrorMessage != null) {
                            DB_Log_Summary__c logEntry = new DB_Log_Summary__c(
                                Account__c = response.sfAccountId,
                                Status__c = 'Failed',
                                Error__c = response.ErrorMessage
                            );
                            errorLogs.add(logEntry);
                            System.debug('API Response Failure: ' + JSON.serialize(logEntry));
                        }
                    }
                }

                
                
                if (!accountsToUpdate.isEmpty()) {
                    Database.SaveResult[] updateResults = Database.update(accountsToUpdate, false);
                    
                    
                    for (Integer i = 0; i < updateResults.size(); i++) {
                        if (!updateResults[i].isSuccess()) {
                            for (Database.Error error : updateResults[i].getErrors()) {
                                DB_Log_Summary__c logEntry = new DB_Log_Summary__c(
                                    Account__c = accountsToUpdate[i].Id,
                                    Status__c = 'Update Failed',
                                    Error__c = error.getMessage()
                                );
                                errorLogs.add(logEntry);
                                System.debug('Database Update Failure: ' + JSON.serialize(logEntry)); // Print failure
                            }
                        }
                    }
                }
            } else {
                //throw new CalloutException('HTTP Error: ' + res.getStatus());
                String errorBody = res.getBody();
                String errorMessage = 'HTTP Error ' + res.getStatusCode() + ': ' + res.getStatus();
                System.debug('errorBody: ' + errorBody);
                System.debug('errorMessage: ' + errorMessage);
                System.debug('errorBody: ' + res.getStatusCode());
                System.debug('getStatusCode: ' + errorMessage);
                for (Account acc : accountList) {
                    DB_Log_Summary__c logEntry = new DB_Log_Summary__c(
                        Account__c = acc.Id,
                        Status__c = 'API Error',
                        Error__c = errorMessage,
                        Response__c = 'Response Body: ' + errorBody
                    );
                    errorLogs.add(logEntry);
                    // System.debug('API Error Log:JSON ' + JSON.serialize(logEntry));
                    
                }
            }
        } catch (Exception e) {
            System.debug('Exception in CVMS Callout: ' + e.getMessage());
            
            
            for (Account acc : accountList) {
                DB_Log_Summary__c logEntry = new DB_Log_Summary__c(
                    Account__c = acc.Id,
                    Status__c = 'API Callout Failed',
                    Error__c = e.getMessage() 
                );
                errorLogs.add(logEntry);
                System.debug('API Callout Failure: ' + JSON.serialize(logEntry)); // Print failure
            }
        }
        
        
        if (!errorLogs.isEmpty()) {
            System.debug('Total Errors Logged: ' + errorLogs.size());
            Database.insert(errorLogs, false);
        }
    }
}