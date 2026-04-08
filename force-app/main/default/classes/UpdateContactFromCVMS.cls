@RestResource(urlMapping='/UpdateCVMSContactData')
global class UpdateContactFromCVMS 
{
    @HttpPost
    global static void updateContactData()
    {
        List<Contact> contactsToUpdate = new List<Contact>();
        List<DB_Log_Summary__c> errorLogs = new List<DB_Log_Summary__c>();
        List<ResponseWrapper> responseList = new List<ResponseWrapper>();
        Map<String, ResponseWrapper> responseMap = new Map<String, ResponseWrapper>();
        
        try 
        {      
            String requestBody = RestContext.request.requestBody.toString();
            system.debug('requestBody==>'+requestBody);
            List<ContactUpdateWrapper>  contactDataList = (List<ContactUpdateWrapper>) JSON.deserialize(requestBody, List<ContactUpdateWrapper>.class);
            
            Set<String> accountIds = new Set<String>();
            for (ContactUpdateWrapper data : contactDataList) 
            {
                if (!String.isBlank(data.AccountId)) 
                {
                    accountIds.add(data.AccountId);
                }
            }
            Map<String, Account> existingAccounts = new Map<String, Account>([SELECT Id FROM Account WHERE Id IN :accountIds]);
            
            for (ContactUpdateWrapper data : contactDataList) 
            {
                if (String.isBlank(data.AccountId)) 
                {
                    generateErrorResponse(responseList, data.ExternalID, data.AccountId, 'Blank accountId');
                    continue;
                }
                if (String.isBlank(data.ExternalID)) 
                {
                    generateErrorResponse(responseList, data.ExternalID, data.AccountId, 'Blank ExternalID');
                    continue;
                }
               /* if (String.isBlank(data.ReportsTo))  
                {
                    generateErrorResponse(responseList, data.ExternalID, data.AccountId, 'Blank ReportID');
                    continue;
                }*/
                if (!existingAccounts.containsKey(data.AccountId)) 
                {
                    generateErrorResponse(responseList, data.ExternalID, null, 'Please check the Account Id');
                    continue;      
                }
                Contact objcon = new Contact();
                objcon.External_Id__c = data.ExternalID;
                objcon.AccountId = data.AccountId;
                objcon.FirstName = data.FirstName;
                objcon.LastName = data.LastName; 
                objcon.Email = data.EmailId;
                objcon.Phone = data.OfficePhone;
                objcon.MobilePhone = data.Mobile;
                objcon.Title = data.Designation;
                objcon.LeadSource = 'CVMS';
                //objcon.ReportsToId = data.ReportsTo != Null?data.ReportsTo:'';
                if (!String.isBlank(data.ReportsTo)) {
                    objcon.ReportsToId = data.ReportsTo;
                }

                contactsToUpdate.add(objcon);
            }
            if (!contactsToUpdate.isEmpty()) 
            {
                List<DataBase.UpsertResult> saveResults = DataBase.Upsert(contactsToUpdate,Contact.External_Id__c,false);
                for (Integer i = 0; i < saveResults.size(); i++) 
                {
                    String externalId = contactsToUpdate[i].External_Id__c;
                    if (saveResults[i].isSuccess()) 
                    {
                        String successMessage = saveResults[i].isCreated() ? 'Contact inserted successfully' : 'Contact updated successfully';
                        responseList.add(new ResponseWrapper(externalId, saveResults[i].getId(), 'Success', successMessage));
                    } else 
                    {
                        String ErrorMessage = saveResults[i].getErrors().isEmpty() ? 'Unknown error' : saveResults[i].getErrors()[0].getMessage();
                        responseList.add(new ResponseWrapper(externalId, null, 'Failure', ErrorMessage));
                        errorLogs.add(new DB_Log_Summary__c(Contact__c = saveResults[i].getId(), Status__c = 'Failed',  Error__c = ErrorMessage));
                    }
                }
            }
            if (!errorLogs.isEmpty()) {
                try {
                    Database.SaveResult[] logResults = Database.insert(errorLogs, false);
                    for (Database.SaveResult logResult : logResults) {
                        if (!logResult.isSuccess()) {
                            System.debug('Failed to insert log: ' + logResult.getErrors()[0].getMessage());
                        }
                    }
                } catch (Exception e) 
                {
                    System.debug('Error inserting logs: ' + e.getMessage());
                }
            }
            responseList.addAll(responseMap.values());
        } 
        catch (Exception e) 
        {
            errorLogs.add(new DB_Log_Summary__c(Status__c = 'Failed', Error__c = 'Unexpected error (' + e.getTypeName() + '): ' + e.getMessage() ));
            Database.insert(errorLogs, false);
            System.debug('Error inserting logs: ' + e.getMessage());
            generateErrorResponse(responseList, null, null, 'Unexpected error: ' + e.getMessage());
        }
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseList));
         //System.debug('responseBody: ' + Blob.valueOf(JSON.serialize(responseList)));
        System.debug('Final Response Sent: ' + JSON.serialize(responseList));

        
    }
    
    private static void generateErrorResponse(List<ResponseWrapper> responseList, string ExternalID, String ContactId, String ErrorMessage) 
    {
        responseList.add(new ResponseWrapper(ExternalID, ContactId, 'Failure', ErrorMessage));
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseList));
    }
    public class ContactUpdateWrapper 
    {
        public String ExternalID;
        public String AccountId;
        public String FirstName;
        public String LastName;
        public String EmailId;
        public String Mobile;
        public String OfficePhone;
        public String Designation;   
        public string ReportsTo;  
    }
    
    public class ResponseWrapper 
    {
        public String ExternalID;   
        public string ContactId; 
        public string Status; 
        public String ErrorMessage;    
        
        public ResponseWrapper(String ExternalID, string ContactId, string Status, String ErrorMessage) 
        {
            this.ExternalID = ExternalID;
            this.ContactId = ContactId;
            this.Status = Status;
            this.ErrorMessage = ErrorMessage;
        }
    }
}