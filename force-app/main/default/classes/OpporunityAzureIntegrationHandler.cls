public class OpporunityAzureIntegrationHandler {
    // private static final String AUTH_URL = System.Label.Digital_Layer_AUTH_URL;
    // private static final String CLIENT_ID = System.Label.Digital_Layer_CLIENT_ID;
    // private static final String CLIENT_SECRET = System.Label.Digital_Layer_CLIENT_SECRET;
    // private static final String SCOPE = System.Label.Digital_Layer_SCOPE;
    // private static final String FUNCTION_APP_URL = System.Label.Digital_Layer_FUNCTION_APP_URL;
    // private static final Integer REQUEST_TIMEOUT = 30000; // Set timeout to 30 seconds

    // Authenticate with Azure
    public static String authenticateWithAzure() {
        System.debug('Starting Azure Authentication...');
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(AUTH_URL);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setTimeout(REQUEST_TIMEOUT);

            String body = 'grant_type=client_credentials'
                        + '&client_id=' + CLIENT_ID
                        + '&client_secret=' + CLIENT_SECRET
                        + '&scope=' + SCOPE;
            req.setBody(body);
            
            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('Azure Authentication Response: ' + res.getBody());
            if (res.getStatusCode() == 200) {
                Map<String, Object> authResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String accessToken = String.valueOf(authResponse.get('access_token'));
                System.debug('Access Token: ' + accessToken);
                return accessToken;
            } else {
                throw new CalloutException('Authentication failed: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Error in Azure Authentication: ' + e.getMessage());
            throw e;
        }
    }

    @future(callout=true)
    public static void sendOppData(List<Id> oppIds) {
        // Query opportunities and related projects
        List<Opportunity> opps = [SELECT Id, Name, Opportunity_Category__c, Request_Type__c, Parent_Opportunity__c, AccountId, Account.Name,
                                  Business_Type__c, Amount, OwnerId, Opportunity_Number__c, Owner.Name, Digital_Layer_ID__c, RFX_Team_Member__c,
                                  CurrencyIsoCode, RFX_Team_Member__r.Name, RFX_Team_Member__r.FederationIdentifier, 
                                  Owner.Email, Folder_Link__c FROM Opportunity WHERE Id IN :oppIds];
        List<Project__c> projects = [SELECT Id, Name, Department__c, Operating_Unit__c, Division__c,
                                     Project_Type__c, Complete_Opportunity_Id__c FROM Project__c WHERE Complete_Opportunity_Id__c IN :oppIds];

        // Prepare data for callout
        Map<Id, List<Project__c>> oppProjectMap = mapProjectsToOpportunities(projects);

        // Process each opportunity
        for (Opportunity opp : opps) {
            Map<String, Object> data = prepareOpportunityData(opp, oppProjectMap);
            sendToAzure(data, opp.Id);
        }
    }

    private static Map<Id, List<Project__c>> mapProjectsToOpportunities(List<Project__c> projects) {
        Map<Id, List<Project__c>> oppProjectMap = new Map<Id, List<Project__c>>();
        for (Project__c proj : projects) {
            if (!oppProjectMap.containsKey(proj.Complete_Opportunity_Id__c)) {
                oppProjectMap.put(proj.Complete_Opportunity_Id__c, new List<Project__c>());
            }
            oppProjectMap.get(proj.Complete_Opportunity_Id__c).add(proj);
        }
        return oppProjectMap;
    }

    private static Map<String, Object> prepareOpportunityData(Opportunity opp, Map<Id, List<Project__c>> oppProjectMap) {
        Map<String, Object> data = new Map<String, Object>();
        data.put('Id', opp.Id);
        data.put('Opportunity_Name', opp.Name);
        data.put('Opportunity_Category', opp.Opportunity_Category__c);
        data.put('Request_Type', opp.Request_Type__c);
        data.put('Account_Id', opp.AccountId);
        data.put('Account_Name', opp.Account.Name);
        data.put('Parent_Opportunity', opp.Parent_Opportunity__c);
        data.put('Business_type', opp.Business_Type__c);
        data.put('Opportunity_Value', opp.Amount);
        data.put('Opportunity_Number', opp.Opportunity_Number__c);
        data.put('Opportunity_Owner_Name', opp.Owner.Name);
        data.put('Opportunity_Owner_Email', opp.Owner.Email);
        data.put('Folder_Link', opp.Folder_Link__c);
        data.put('opportunitY_DIGITAL_ID', opp.Digital_Layer_ID__c);
        data.put('Opportunity_Currency', opp.CurrencyIsoCode);
        data.put('RFX_Team_Member', opp.RFX_Team_Member__r.Name);
        data.put('RFX_Team_Member_Email', opp.RFX_Team_Member__r.FederationIdentifier);


        // Determine operation type based on the presence of Digital_Layer_ID__c
        if (String.isEmpty(opp.Digital_Layer_ID__c)) {
            data.put('operation', 'insert');
        } else {
            data.put('operation', 'update');
        }

        List<Map<String, Object>> projectList = new List<Map<String, Object>>();
        if (oppProjectMap.containsKey(opp.Id)) {
            for (Project__c proj : oppProjectMap.get(opp.Id)) {
                Map<String, Object> projectData = new Map<String, Object>();
                projectData.put('Id', proj.Id);
                projectData.put('Name', proj.Name);
                projectData.put('Department', proj.Department__c);
                projectData.put('Operating_Unit', proj.Operating_Unit__c);
                projectData.put('Division', proj.Division__c);
                projectData.put('Project_Type', proj.Project_Type__c);

                projectList.add(projectData);
            }
        }
        data.put('Projects', projectList);

        return data;
    }

    private static void sendToAzure(Map<String, Object> data, Id oppId) {
        String accessToken = authenticateWithAzure();
        if (accessToken == null) {
            System.debug('Unable to obtain access token, aborting data send.');
            return;
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(FUNCTION_APP_URL);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
        request.setTimeout(REQUEST_TIMEOUT);

        request.setBody(JSON.serialize(data));

        try {
            HttpResponse response = http.send(request);
            System.debug('Azure Response Status: ' + response.getStatusCode());
            System.debug('Azure Response Body: ' + response.getBody());

            if (response.getStatusCode() == 200 && !String.isEmpty(response.getBody())) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                if (data.get('operation') == 'insert' && responseMap.containsKey('opportunitY_DIGITAL_ID')) {
                    Integer digitalID = (Integer) responseMap.get('opportunitY_DIGITAL_ID');
                    updateOpportunityDigitalID(oppId, digitalID);
                }
            } else {
                System.debug('Error response: ' + response.getBody());
            }

        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    private static void updateOpportunityDigitalID(Id oppId, Integer digitalID) {
        try {
            Opportunity opp = [SELECT Digital_Layer_ID__c FROM Opportunity WHERE Id = :oppId LIMIT 1];
            opp.Digital_Layer_ID__c = String.valueOf(digitalID);
            update opp;
            System.debug('Updated Opportunity Digital Layer ID: ' + digitalID);
        } catch (Exception e) {
            System.debug('Error updating Opportunity Digital Layer ID: ' + e.getMessage());
        }
    }

    public static Boolean isExecuted = false;

    public static void processOpportunities(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppsMap) {
        Set<Id> oppIdsToProcess = new Set<Id>();

        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldOppsMap.get(opp.Id);
           
            if (opp.Send_Opportunity_data_to_DL__c == true && (oldOpp == null || oldOpp.Send_Opportunity_data_to_DL__c != true)) {
                oppIdsToProcess.add(opp.Id);
            }
        }

        if (!oppIdsToProcess.isEmpty()) {
            System.debug('Trigger is calling sendOppData method.');
            OpporunityAzureIntegrationHandler.sendOppData(new List<Id>(oppIdsToProcess));
        }
    }
}



/*public class OpporunityAzureIntegrationHandler {
    private static final String AUTH_URL = 'https://login.microsoftonline.com/c43083c0-cc01-4eaa-ba4e-d8b6f7c13b95/oauth2/v2.0/token'; 
    private static final String CLIENT_ID = 'b966f197-35dd-4ca5-81ce-23ff666df348'; 
    private static final String CLIENT_SECRET = '6328Q~8PIBYM3qnoejD.d~Jc0fPhKpbvZ~mPoa8h'; 
    private static final String SCOPE = 'api://b966f197-35dd-4ca5-81ce-23ff666df348/.default'; 
    private static final String FUNCTION_APP_URL = 'https://dvegadev.azurewebsites.net/api/Salesforce/Opportunity?code=gepw_Qj5fh40prC4XJl8CXZpEl8yRQA_fuu0Skf8OwOrAzFukCiGzg%3D%3D'; 

    // Authenticate with Azure
    public static String authenticateWithAzure() {
        System.debug('Starting Azure Authentication...');
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(AUTH_URL);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

            String body = 'grant_type=client_credentials'
                        + '&client_id=' + CLIENT_ID
                        + '&client_secret=' + CLIENT_SECRET
                        + '&scope=' + SCOPE;
            req.setBody(body);

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('Azure Authentication Response: ' + res.getBody());
            if (res.getStatusCode() == 200) {
                Map<String, Object> authResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String accessToken = String.valueOf(authResponse.get('access_token'));
                System.debug('Access Token: ' + accessToken);
                return accessToken;
            } else {
                throw new CalloutException('Authentication failed: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Error in Azure Authentication: ' + e.getMessage());
            throw e;
        }
    }
    
  @future(callout=true)  
    public static void sendOppData(List<Id> oppIds) {  
    // Query opportunities and related projects  
    List<Opportunity> opps = [SELECT Id, Name, Opportunity_Category__c, Request_Type__c, Parent_Opportunity__c, AccountId, Account.Name, 
                              Business_Type__c, Amount, OwnerId, Opportunity_Number__c, Owner.Name, Digital_Layer_ID__c,   
                              Owner.Email, Folder_Link__c FROM Opportunity WHERE Id IN :oppIds];  
    List<Project__c> projects = [SELECT Id, Name, Department__c, Operating_Unit__c, Division__c,   
                                 Project_Type__c, Complete_Opportunity_Id__c FROM Project__c WHERE Complete_Opportunity_Id__c IN :oppIds];  
  
    // Prepare data for callout  
    Map<Id, List<Project__c>> oppProjectMap = new Map<Id, List<Project__c>>();  
    for (Project__c proj : projects) {  
        if (!oppProjectMap.containsKey(proj.Complete_Opportunity_Id__c)) {  
            oppProjectMap.put(proj.Complete_Opportunity_Id__c, new List<Project__c>());  
        }  
        oppProjectMap.get(proj.Complete_Opportunity_Id__c).add(proj);  
    }  
  
    List<Map<String, Object>> dataList = new List<Map<String, Object>>();  
  
    for (Opportunity opp : opps) {  
        Map<String, Object> data = new Map<String, Object>();  
        data.put('Id', opp.Id);  
        data.put('Opportunity_Name', opp.Name);  
        data.put('Opportunity_Category', opp.Opportunity_Category__c);  
        data.put('Request_Type', opp.Request_Type__c);  
        data.put('Account_Id', opp.AccountId);  
        data.put('Account_Name', opp.Account.Name);  
        data.put('Parent_Opportunity', opp.Parent_Opportunity__c);  
        data.put('Business_type', opp.Business_Type__c);  
        data.put('Opportunity_Value', opp.Amount);  
        data.put('Opportunity_Number', opp.Opportunity_Number__c);  
        data.put('Opportunity_Owner_Name', opp.Owner.Name);  
        data.put('Opportunity_Owner_Email', opp.Owner.Email);  
        data.put('Folder_Link', opp.Folder_Link__c);  
  
        List<Map<String, Object>> projectList = new List<Map<String, Object>>();  
        if (oppProjectMap.containsKey(opp.Id)) {  
            for (Project__c proj : oppProjectMap.get(opp.Id)) {  
                Map<String, Object> projectData = new Map<String, Object>();  
                projectData.put('Id', proj.Id);  
                projectData.put('Name', proj.Name);  
                projectData.put('Department', proj.Department__c);  
                projectData.put('Operating_Unit', proj.Operating_Unit__c);  
                projectData.put('Division', proj.Division__c);  
                projectData.put('Project_Type', proj.Project_Type__c);  
                projectList.add(projectData);  
            }  
        }  
        data.put('Projects', projectList);  
        dataList.add(data);  
    }  
  
    sendToAzure(dataList);  
}  
  
/*private static void sendToAzure(List<Map<String, Object>> dataList) {    
    String accessToken = authenticateWithAzure();    
    if (accessToken == null) {    
        System.debug('Unable to obtain access token, aborting data send.');    
        return;    
    }    
    
    Http http = new Http();    
    List<HttpRequest> requests = new List<HttpRequest>();    
    Map<Id, String> oppIdToDigitalIdMap = new Map<Id, String>();    
    
    for (Map<String, Object> data : dataList) {    
        HttpRequest request = new HttpRequest();    
        request.setEndpoint(FUNCTION_APP_URL);    
        request.setMethod('POST');    
        request.setHeader('Content-Type', 'application/json');    
        request.setHeader('Authorization', 'Bearer ' + accessToken);    
        request.setBody(JSON.serialize(data));    
        requests.add(request);    
    }    
    
    for (HttpRequest request : requests) {    
        try {    
            HttpResponse response = http.send(request);    
            System.debug('Response status: ' + response.getStatusCode());    
            System.debug('Response body: ' + response.getBody());    
    
            if (String.isEmpty(response.getBody())) {    
                System.debug('Response Body is empty.');    
                continue;    
            }    
    
            if (response.getStatusCode() != 200) {    
                System.debug('Error response from Azure: ' + response.getBody());    
                continue;    
            } else {    
                AzureResponseWrapper responseBody =     
                    (AzureResponseWrapper) JSON.deserialize(response.getBody(), AzureResponseWrapper.class);    
    
                if (responseBody.opportunitY_DIGITAL_ID != null) {    
                    String oppIdStr = String.valueOf(dataList.get(requests.indexOf(request)).get('Id'));    
                    Id oppId = Id.valueOf(oppIdStr);    
                    oppIdToDigitalIdMap.put(oppId, responseBody.opportunitY_DIGITAL_ID);    
                }    
            }    
        } catch (Exception e) {    
            System.debug('Exception during HTTP callout: ' + e.getMessage());    
        }    
    }    
    
    List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();    
    for (Id oppId : oppIdToDigitalIdMap.keySet()) {    
        Opportunity oppToUpdate = new Opportunity(Id = oppId, Digital_Layer_ID__c = oppIdToDigitalIdMap.get(oppId));    
        opportunitiesToUpdate.add(oppToUpdate);    
    }    
    
    if (!opportunitiesToUpdate.isEmpty()) {    
        try {  
            update opportunitiesToUpdate;    
        } catch (DmlException ex) {  
            System.debug('DML Exception: ' + ex.getMessage());  
        }  
    }    
}  */  
    
/*public class AzureResponseWrapper {    
    public String opportunitY_DIGITAL_ID;    
    public String status;    
    public String message;    
}  
  private static String sendToAzure(Map<String, Object> data) {  
    String accessToken = authenticateWithAzure();  
    if (accessToken == null) {  
        System.debug('Unable to obtain access token, aborting data send.');  
        return null;  
    }  
  
    Http http = new Http();  
    HttpRequest request = new HttpRequest();  
    request.setEndpoint(FUNCTION_APP_URL);  
    request.setMethod('POST');  
    request.setHeader('Content-Type', 'application/json');  
    request.setHeader('Authorization', 'Bearer ' + accessToken);  
  
    request.setBody(JSON.serialize(data));  
  
    try {  
        HttpResponse response = http.send(request);  
        System.debug('Azure Response Status: ' + response.getStatusCode());  
        System.debug('Azure Response Body: ' + response.getBody());  
  
        // Check if the response body is empty or malformed  
        if (String.isEmpty(response.getBody())) {  
            System.debug('Response Body is empty.');  
            throw new CalloutException('Response Body is empty.');  
        }  
  
        // If status code is not 200, log the error  
        if (response.getStatusCode() != 200) {  
            System.debug('Error response: ' + response.getBody());  
            return null;  
        } else {  
            // Parse the response to get the Digital Layer ID  
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());  
             if (responseBody.containsKey('opportunitY_DIGITAL_ID')) {  
                String digitalId = (String) responseBody.get('opportunitY_DIGITAL_ID');  
                System.debug('Received opportunitY_DIGITAL_ID: ' + digitalId);  
                return digitalId;  
            }  
        }  
    } catch (Exception e) {  
        System.debug('Exception: ' + e.getMessage());  
    }  
  
    return null;  
}  

}*/