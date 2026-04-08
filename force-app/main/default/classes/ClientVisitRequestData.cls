@RestResource(urlMapping='/UpdateClientVisitCVMSData')
global class ClientVisitRequestData 
{
    @HttpPost
    global static void updateClientVistCVMS() {
        List<Client_Visit_CVMS__c> clientVisitCVMSToUpdate = new List<Client_Visit_CVMS__c>();
        List<Visitor_CVMS__c> visitorCVMSToUpdate = new List<Visitor_CVMS__c>();
        List<DB_Log_Summary__c> errorLogs = new List<DB_Log_Summary__c>();
        List<ResponseWrapper> responseList = new List<ResponseWrapper>();
        
        Set<String> validClientHierarchyValues = new Set<String>();
        Schema.DescribeFieldResult fieldResult = Visitor_CVMS__c.Client_Hierarchy__c.getDescribe();
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            validClientHierarchyValues.add(picklistEntry.getValue());
        }
        
        try {
            String requestBody = RestContext.request.requestBody.toString();
            System.debug('Request Body: ' + requestBody);
            
            /*List<ClientVisitorUpdateWrapper> clientDataList =
(List<ClientVisitorUpdateWrapper>) JSON.deserialize(requestBody, List<ClientVisitorUpdateWrapper>.class);*/
            List<Object> rawList = (List<Object>) JSON.deserializeUntyped(requestBody);
            System.debug('rawList**********'+rawList);
            Map<String, ResponseWrapper> responseMap = new Map<String, ResponseWrapper>();
            List<ClientVisitorUpdateWrapper> clientDataList = new List<ClientVisitorUpdateWrapper>(); 
            
            for (Object obj : rawList) {
                Map<String, Object> rawRecord = (Map<String, Object>) obj;
                String trackingId = (String) rawRecord.get('ClientTrackingNumberExtID');
                ResponseWrapper responseWrapper = new ResponseWrapper(trackingId, 'Success', null);
                
                try {
                    
                    ClientVisitorUpdateWrapper parsed = (ClientVisitorUpdateWrapper)
                        JSON.deserialize(JSON.serialize(rawRecord), ClientVisitorUpdateWrapper.class);
                    
                    clientDataList.add(parsed);
                    responseMap.put(trackingId, responseWrapper);
                } catch (Exception ex) {
                    responseWrapper.Status = 'Failure';
                    responseWrapper.ErrorMessage = 'Invalid data for record: ' + ex.getMessage();
                    responseList.add(responseWrapper);
                    
                    errorLogs.add(new DB_Log_Summary__c(
                        Status__c = 'Failed',
                        Error__c = 'Invalid data for record: ' + ex.getMessage(),
                        Request__c = JSON.serialize(rawRecord)
                    ));
                }
            }
            
            
            Set<String> accountIds = new Set<String>();
            Set<String> contactIds = new Set<String>();
            Set<String> clientTrackingNumbers = new Set<String>();
            Map<String, ClientVisitorUpdateWrapper> clientDataMap = new Map<String, ClientVisitorUpdateWrapper>();
            
            for (ClientVisitorUpdateWrapper data : clientDataList) {
                if (!String.isBlank(data.AccountID)) {
                    accountIds.add(data.AccountID);
                }
                if (!String.isBlank(data.ClientTrackingNumberExtID)) {
                    clientTrackingNumbers.add(data.ClientTrackingNumberExtID);
                    clientDataMap.put(data.ClientTrackingNumberExtID, data);
                }
                for (VisitWrapper visit : data.VisitsCVMC) {
                    if (!String.isBlank(visit.ContactID)) {
                        contactIds.add(visit.ContactID);
                    }
                }
            }
            
            Map<String, Account> existingAccounts = accountIds.isEmpty() ? new Map<String, Account>(): new Map<String, Account>([SELECT Id FROM Account WHERE Id IN :accountIds]); 
            
            
            Map<String, Contact> existingContacts = contactIds.isEmpty() ? new Map<String, Contact>(): new Map<String, Contact>([SELECT Id, Name FROM Contact WHERE Id IN :contactIds]);
            
            
            Map<String, Client_Visit_CVMS__c> existingClientVisits = new Map<String, Client_Visit_CVMS__c>();
            
            if (!clientTrackingNumbers.isEmpty()) {
                for (Client_Visit_CVMS__c visit : [ SELECT Id, Client_Tracking_Number__c FROM Client_Visit_CVMS__c  WHERE Client_Tracking_Number__c IN :clientTrackingNumbers ])  
                    
                {
                    existingClientVisits.put(visit.Client_Tracking_Number__c, visit);
                }
            }
            
            
            
            for (ClientVisitorUpdateWrapper data : clientDataList) {
                ResponseWrapper responseWrapper = new ResponseWrapper(data.ClientTrackingNumberExtID, 'Success', null);
                responseMap.put(data.ClientTrackingNumberExtID, responseWrapper);
                
                if (String.isBlank(data.ClientTrackingNumberExtID)) {
                    responseWrapper.Status = 'Failure';
                    responseWrapper.ErrorMessage = 'Blank ExternalID';
                    errorLogs.add(new DB_Log_Summary__c(
                        Status__c = 'Failed',
                        Error__c = 'Blank ExternalID',
                        Request__c = requestBody
                    ));
                    responseList.add(responseWrapper);
                    continue;
                }
                
                if (String.isBlank(data.AccountID) || !existingAccounts.containsKey(data.AccountID)) {
                    responseWrapper.Status = 'Failure';
                    responseWrapper.ErrorMessage = 'Invalid Account ID: ' + data.AccountID;
                    Id clientVisitId = existingClientVisits.containsKey(data.ClientTrackingNumberExtID) ?
                        existingClientVisits.get(data.ClientTrackingNumberExtID).Id : null;
                    errorLogs.add(new DB_Log_Summary__c(
                        Status__c = 'Failed',
                        Client_Visit_CVMS__c = clientVisitId,
                        Error__c = 'Invalid Account ID: ' + data.AccountID,
                        Request__c = requestBody
                    ));
                    responseList.add(responseWrapper);
                    continue;
                }
                
                Client_Visit_CVMS__c objClientVisit = new Client_Visit_CVMS__c(
                    Name = data.ClientTrackingNumberExtID + ' - ' + data.Portfolio + ' - ' + data.NumberOfPeopleVisiting,
                    Client_Tracking_Number__c = data.ClientTrackingNumberExtID,
                    Visit_Start_Date__c = data.VisitorStartDate,
                    Visit_End_Date__c = data.VisitorEndDate,
                    Account__c = data.AccountID,
                    Syngene_Facility__c = data.SyngeneFacility,
                    Number_of_People_Visiting__c = data.NumberOfPeopleVisiting,
                    Customer_Segment__c = data.CustomerSegment,
                    Industry__c = data.Industry,
                    Portfolio__c =data.Portfolio != null ? data.Portfolio.replace(',', ';') : null,
                    //Operating_Unit__c = data.OperatingUnit,
                    Operating_Unit__c = data.OperatingUnit != null ? data.OperatingUnit.replace(',', ';') : null,
                    
                    Purpose_of_Visit__c = data.PurposeofVisit,
                    Visit_Status__c = data.VisitStatus,
                    Client_Geo__c = data.ClientGeo,
                    Client_Location__c = data.ClientLocation
                );
                
                clientVisitCVMSToUpdate.add(objClientVisit);
            }
            
            if (!clientVisitCVMSToUpdate.isEmpty()) {
                Database.UpsertResult[] upsertResults = Database.upsert(clientVisitCVMSToUpdate, Client_Visit_CVMS__c.Client_Tracking_Number__c, false);
                Map<Id, String> clientVisitIdToTrackingNumber = new Map<Id, String>();
                Map<Id, VisitWrapper> visitorIdToWrapperMap = new Map<Id, VisitWrapper>();
                
                for (Integer i = 0; i < upsertResults.size(); i++) {
                    Client_Visit_CVMS__c updatedClientVisit = clientVisitCVMSToUpdate[i];
                    Database.UpsertResult result = upsertResults[i];
                    String trackingId = updatedClientVisit.Client_Tracking_Number__c;
                    ClientVisitorUpdateWrapper data = clientDataMap.get(trackingId);
                    
                    ResponseWrapper responseWrapper = responseMap.get(trackingId);
                    responseWrapper.VisitResponses = new List<VisitResponseWrapper>();
                    
                    if (result.isSuccess()) {
                        clientVisitIdToTrackingNumber.put(result.getId(), trackingId);
                        for (VisitWrapper visit : data.VisitsCVMC) {
                           
                            
                            if (String.isBlank(visit.GuestId)) {
                                // handle missing external ID error
                                VisitResponseWrapper visitResponse = new VisitResponseWrapper(
                                    visit.ContactID,
                                    'Failure',
                                    'Missing GuestId'
                                );
                                responseWrapper.VisitResponses.add(visitResponse);
                                errorLogs.add(new DB_Log_Summary__c(
                                    Status__c = 'Failed',
                                    Error__c = 'Missing GuestId',
                                    Request__c = JSON.serialize(visit),
                                     Client_Visit_CVMS__c = result.getId()
                                ));
                                continue;
                            }
                            
                            Visitor_CVMS__c visitorRecord = new Visitor_CVMS__c(
                                Visitor_CVMS_Id__c = visit.GuestId,
                                Name = visit.ContactID != null && existingContacts.containsKey(visit.ContactID) ? existingContacts.get(visit.ContactID).Name : 'Visitor--'+visit.GuestId + '-' + result.getId(),
                                                               
                                External_ID__c = visit.GuestId + '-' + result.getId(), 
                                Client_Hierarchy__c = visit.ClientHierarchy,
                                Client_Visit__c = result.getId()
                            );
                            if (!String.isBlank(visit.ContactID) && existingContacts.containsKey(visit.ContactID)) {
    visitorRecord.Contact__c = visit.ContactID;
}
                            visitorCVMSToUpdate.add(visitorRecord);

                            visitorIdToWrapperMap.put(visitorRecord.Id, visit);
                            
                            
                            
                        }
                    } else {
                        responseWrapper.Status = 'Failure';
                        responseWrapper.ErrorMessage = result.getErrors()[0].getMessage();
                        
                        for (VisitWrapper visit : data.VisitsCVMC) {
                            VisitResponseWrapper visitResponse = new VisitResponseWrapper(
                                visit.ContactID, 'Failure', 'Skipped due to parent client visit insert failure.'
                            );
                            errorLogs.add(new DB_Log_Summary__c(
                                Status__c = 'Failed',
                                Error__c = 'Client Visit upsert failed: ' + result.getErrors()[0].getMessage(),
                                Request__c = JSON.serialize(data)
                            ));
                            
                            responseWrapper.VisitResponses.add(visitResponse);
                        }
                    }
                    
                    responseList.add(responseWrapper);
                }
                
                if (!visitorCVMSToUpdate.isEmpty()) {
                    Database.UpsertResult[] visitorUpsertResults = Database.upsert(visitorCVMSToUpdate, Visitor_CVMS__c.External_ID__c, false);
                    
                    
                    
                    for (Integer i = 0; i < visitorUpsertResults.size(); i++) {
                        Database.UpsertResult res = visitorUpsertResults[i];
                        Visitor_CVMS__c visitorRecord = visitorCVMSToUpdate[i];
                        String trackingNumber = clientVisitIdToTrackingNumber.get(visitorRecord.Client_Visit__c);
                        VisitResponseWrapper visitResponse;
                        
                        if (res.isSuccess()) {
                            visitResponse = new VisitResponseWrapper(visitorRecord.Contact__c, 'Success', null);
                        } else {
                            visitResponse = new VisitResponseWrapper(visitorRecord.Contact__c, 'Failure', res.getErrors()[0].getMessage());
                            errorLogs.add(new DB_Log_Summary__c(
                                Status__c = 'Failed',
                                Error__c = 'Visitor upsert error: ' + res.getErrors()[0].getMessage(),
                                Request__c = requestBody
                            ));
                        }
                        
                        ResponseWrapper response = responseMap.get(trackingNumber);
                        if (response != null) {
                            response.VisitResponses.add(visitResponse);
                        }
                    }
                    
                    
                    
                }
                
            }
            
            if (!errorLogs.isEmpty()) {
                Database.insert(errorLogs, false);
            }
            
        } catch (Exception e) {
            errorLogs.add(new DB_Log_Summary__c(Status__c = 'Failed', Error__c = 'Unexpected error (' + e.getTypeName() + '): ' + e.getMessage()));
            Database.insert(errorLogs, false);
            
            ResponseWrapper errorResponse = new ResponseWrapper(null, 'Failure', 'An unexpected error occurred: ' + e.getMessage());
            responseList.add(errorResponse);
            System.debug('An unexpected error occurred: ' + e.getMessage());
        }
        
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseList));
        System.debug('responseBody: ' + Blob.valueOf(JSON.serialize(responseList)));
        System.debug('Final Response Sent: ' + JSON.serialize(responseList));
        
    }
    public class ClientVisitorUpdateWrapper 
    {
        public String ClientTrackingNumberExtID;
        public Date VisitorStartDate;
        public Date VisitorEndDate;
        public String AccountID;
        public String SyngeneFacility;
        public Decimal NumberOfPeopleVisiting;
        public String CustomerSegment;
        public String Industry;
        public String Portfolio;
        public String OperatingUnit;
        public String PurposeofVisit;
        public String VisitStatus;
        public String ClientGeo;
        public String ClientLocation;
        public List<VisitWrapper> VisitsCVMC = new List<VisitWrapper>();
    }
    
    public class VisitWrapper 
    {
        public String ContactID;
        public String ClientHierarchy;
        public String GuestId;
    }
    
    
    public class VisitResponseWrapper 
    {
        public String ContactID;
        public String Status;
        public String ErrorMessage;
        
        public VisitResponseWrapper(String contactID, String status, String errorMessage) 
        {
            this.ContactID = contactID;
            this.Status = status;
            this.ErrorMessage = errorMessage;
        }
    }
    
    public class ResponseWrapper 
    {
        public String ClientTrackExternalID;
        public String Status;
        public String ErrorMessage;
        public List<VisitResponseWrapper> VisitResponses = new List<VisitResponseWrapper>();
        
        public ResponseWrapper(String clientTrackExternalID, String status, String errorMessage) 
        {
            this.ClientTrackExternalID = clientTrackExternalID;
            this.Status = status;
            this.ErrorMessage = errorMessage;
        }
    }
}