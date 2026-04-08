public with sharing class CVMS_ContactSyncService {
    
   
    
    public static void sendContactsToCVMS(List<Contact> contactList) {
        if (contactList.isEmpty()) return;
        
        List<Contact> contactsToUpdate = new List<Contact>();
        List<DB_Log_Summary__c> errorLogs = new List<DB_Log_Summary__c>();
        
        try {
            HttpRequest req = new HttpRequest();
            
            req.setEndpoint('callout:CVMS_Named_CSF/Services/api/salesforce/contacts/upsert');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            
        
            
             List<CVMS_ContactWrapper.ContactData> requestBody = new List<CVMS_ContactWrapper.ContactData>();
            for (Contact con : contactList) {
                requestBody.add(new CVMS_ContactWrapper.ContactData(con));
            }
			req.setBody(JSON.serialize(requestBody));
            System.debug('requestBody: ' +requestBody); 
            System.debug('requestBody: ' +JSON.serialize(requestBody)); 
            //req.setBody(requestJSON);
            System.debug('requestBody: ' +requestBody); 
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            
            System.debug('res.getStatusCode(): ' + res.getStatusCode()); 
            System.debug('res.getBody(): ' + res.getBody()); 
            if (res.getStatusCode() == 200) {
               /* CVMS_ContactWrapper.Response responseBody = 
                    (CVMS_ContactWrapper.Response) JSON.deserialize(res.getBody(), CVMS_ContactWrapper.Response.class);*/
                 List<CVMS_ContactWrapper.ResponseData> responseList =
                    (List<CVMS_ContactWrapper.ResponseData>) JSON.deserialize(res.getBody(), List<CVMS_ContactWrapper.ResponseData>.class);
                
                for (CVMS_ContactWrapper.ResponseData response : responseList) {
                    Boolean isSuccess = (response.statusCode == '200' && response.status != 'Failure');
                    
                    if (isSuccess && response.sfContactId != null) {
                        contactsToUpdate.add(new Contact(
                            Id = response.sfContactId,
                            Integrated_with_CVMS__c = true
                        ));
                    } else if (response.sfContactId != null) {
                        DB_Log_Summary__c logEntry = new DB_Log_Summary__c(
                            Contact__c = response.sfContactId,
                            Status__c = 'Failed',
                            Error__c = response.message
                        );
                        errorLogs.add(logEntry);
                        //System.debug('API Response Failure: ' + JSON.serialize(logEntry));
                    }
                }
                
                if (!contactsToUpdate.isEmpty()) {
                    Database.SaveResult[] updateResults = Database.update(contactsToUpdate, false);
                    
                    for (Integer i = 0; i < updateResults.size(); i++) {
                        if (!updateResults[i].isSuccess()) {
                            for (Database.Error error : updateResults[i].getErrors()) {
                                DB_Log_Summary__c logEntry = new DB_Log_Summary__c(
                                    Contact__c = contactsToUpdate[i].Id,
                                    Status__c = 'Update Failed',
                                    Error__c = error.getMessage()
                                );
                                errorLogs.add(logEntry);
                                System.debug('Database Update Failure: ' + JSON.serialize(logEntry)); 
                            }
                        }
                    }
                }
            } else {
               
                
                String errorBody = res.getBody();
                String errorMessage = 'HTTP Error ' + res.getStatusCode() + ': ' + res.getStatus();
                System.debug('errorBody: ' + errorBody);
                  System.debug('errorMessage: ' + errorMessage);
                 System.debug('errorBody: ' + res.getStatusCode());
                  System.debug('getStatusCode: ' + errorMessage);
                for (Contact con : contactList) {
                    DB_Log_Summary__c logEntry = new DB_Log_Summary__c(
                        Contact__c = con.Id,
                        Status__c = 'API Error',
                        Error__c = errorMessage,
                        Response__c = 'Response Body: ' + errorBody
                    );
                    errorLogs.add(logEntry);
                    System.debug('API Error Log: ' + JSON.serialize(logEntry));
                    
                }
            }
        } catch (Exception e) {
            System.debug('Exception in CVMS Contact Callout: ' + e.getMessage());
            
            String failedRequestJSON = JSON.serialize(new CVMS_ContactWrapper.Request(contactList));
            System.debug('Failed Request JSON: ' + failedRequestJSON);
            
            for (Contact con : contactList) {
                DB_Log_Summary__c logEntry = new DB_Log_Summary__c(
                    Contact__c = con.Id,
                    Status__c = 'API Callout Failed',
                    Error__c = e.getMessage()+''+failedRequestJSON
                    
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