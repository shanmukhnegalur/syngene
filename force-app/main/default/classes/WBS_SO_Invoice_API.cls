/**
* This class is for an API in which we'll get Request from SAP
* This is a batch API, we'll be getting request once in a day
* In Request we'll get WBS, Sale Order and Invoice Information
* This API will map all the data and Upsert the same with the corrosponding SAP Unique Ids by linking to their respective parent records
* Partial Success allowed for all 3 objects and we'll be returning the response accordingly
* 
*/
@RestResource(urlMapping='/WBS_SO_Invoice_API/*')
global class WBS_SO_Invoice_API
{
    @HttpPost
    global static responseWrapper getDetails()
    {
        responseWrapper resWpr = new responseWrapper();
        resWpr.Opporutnity_Record = new List<resOpporutnityWrapper>();
        resWpr.Sales_Record = new List<resSalesWrapper>();
        resWpr.Invoice_Record = new List<resInvoiceWrapper>();
        
        string jsonReqBody;
        //Get the Request
        RequestWrapper reqWrp = new RequestWrapper();
        RestRequest request = RestContext.request;
        jsonReqBody = request.requestBody.toString();
        
        Integer wbsSuccessCount = 0;
        Integer soSuccessCount = 0;
        Integer invSuccessCount = 0;
        Integer wbsFailCount = 0;
        Integer soFailCount = 0;
        Integer invFailCount = 0;
        
        DB_Log_Summary__c dbS = new DB_Log_Summary__c();
        Insert dbS;
        
        ContentVersion cVersionReq = new ContentVersion();
        cVersionReq.PathOnClient = 'Request from SAP'+'.txt';
        cVersionReq.Title = 'Request from SAP';
        cVersionReq.FirstPublishLocationId = dbS.Id;
        cVersionReq.VersionData = Blob.Valueof(jsonReqBody);
        cVersionReq.IsMajorVersion = true;
        Insert cVersionReq;
        Savepoint sp = Database.setSavepoint();
        try{
            //Deserilize the request Json recived to the local wrappers
            reqWrp = (RequestWrapper) Json.deserialize(jsonReqBody , RequestWrapper.class);
            //system.debug('reqWrp: ' + reqWrp);
            
            List<OpporutnityWrapper> listOptywrapper2 = new List<OpporutnityWrapper>();
            List<SalesWrapper> salesWrapperList = new List<SalesWrapper>();
            List<InvoiceWrapper> InvoiceWrapperList = new List<InvoiceWrapper>();
            
            //Map variable to collect Account Ids to the corrosponding Opportunities
            Map<Id, Opportunity> map_Opportunity = new Map<Id, Opportunity>();
            Set<String> set_OppIds = new Set<String>();
            if(reqWrp.Opporutnity_Record != null && reqWrp.Opporutnity_Record.size() > 0){
                for(OpporutnityWrapper opWpr : reqWrp.Opporutnity_Record){
                    if(String.isNotBlank(opWpr.Id) && opWpr.Id.length() == 18 && opWpr.Id.startsWithIgnoreCase('006')){
                        set_OppIds.add(opWpr.ID);
                        listOptywrapper2.add(opWpr);
                    }
                }
            }
            if(reqWrp.Sales_Record != null && reqWrp.Sales_Record.size() > 0){
                for(SalesWrapper soWpr : reqWrp.Sales_Record){
                    if(String.isNotBlank(soWpr.Opporunity_Id) && soWpr.Opporunity_Id.length() == 18 && soWpr.Opporunity_Id.startsWithIgnoreCase('006')){
                        set_OppIds.add(soWpr.Opporunity_Id);
                        salesWrapperList.add(soWpr);
                    }
                }
            }
            if(reqWrp.Invoice_Record != null && reqWrp.Invoice_Record.size() > 0){
                for(InvoiceWrapper invWpr : reqWrp.Invoice_Record){
                    if(String.isNotBlank(invWpr.Opporunity_Id) && invWpr.Opporunity_Id.length() == 18 && invWpr.Opporunity_Id.startsWithIgnoreCase('006')){
                        set_OppIds.add(invWpr.Opporunity_Id);
                        InvoiceWrapperList.add(invWpr);
                    }
                }
            }
            
            if(!set_OppIds.isEmpty()){
                map_Opportunity = new Map<Id, Opportunity>([SELECT Id,AccountId FROM Opportunity WHERE Id IN: set_OppIds]);
            }
            
            //Mapping Objects data
            Map<String, WBS__c> mapWBStoUpsert = new Map<String, WBS__c>();
            Map<String, Sales_Order__c> mapSOsToUpsert = new Map<String, Sales_Order__c>();
            Map<String, Invoice__c> mapInvoicesToUpsert = new Map<String, Invoice__c>();
            
            //Processing WBS Records
            if(listOptywrapper2.size() > 0){
                for(OpporutnityWrapper opWpr : listOptywrapper2){
                    //if(map_Opportunity.containsKey(opWpr.Id)){
                        WBS__c objWBS = newWBS(opWpr.WBS, opWpr.Id, map_Opportunity);
                        mapWBStoUpsert.put(objWBS.WBS_ID__c, objWBS);
                    //} 
                }
            }
            
            //Processing Sale Order Records
            if(salesWrapperList.size() > 0){
                for(SalesWrapper soWpr : salesWrapperList){
                    //if(String.isNotBlank(soWpr.Opporunity_Id) && map_Opportunity.containsKey(soWpr.Opporunity_Id)){
                        //Mapping WBS from Sale Order
                        WBS__c objWBS = newWBS(soWpr.WBS, soWpr.Opporunity_Id, map_Opportunity);
                        mapWBStoUpsert.put(objWBS.WBS_ID__c, objWBS);
                        
                        Sales_Order__c soRec = newSaleOrder(soWpr.WBS, soWpr.Opporunity_Id, soWpr.SalesOrder, soWpr.SalesOrderDate, soWpr.Customer, soWpr.CustomerName, map_Opportunity);
                        mapSOsToUpsert.put(soRec.External_Id__c, soRec);
                    //}
                }
            }
            
            //Processing Invoice Records
            if(InvoiceWrapperList.size() > 0){
                for(InvoiceWrapper invWpr : InvoiceWrapperList){
                    //if( String.isNotBlank(invWpr.Opporunity_Id) && map_Opportunity.containsKey(invWpr.Opporunity_Id)){
                        //Mapping WBS from Invoice
                        WBS__c objWBS = newWBS(invWpr.WBS_Id, invWpr.Opporunity_Id, map_Opportunity);
                        mapWBStoUpsert.put(objWBS.WBS_ID__c, objWBS);
                        //Mapping Sale Order from Invoice
                        Sales_Order__c soRec = newSaleOrder(invWpr.WBS_Id, invWpr.Opporunity_Id, invWpr.SalesOrder, invWpr.SalesOrderDate, invWpr.Customer, invWpr.CustomerName, map_Opportunity);
                        mapSOsToUpsert.put(soRec.External_Id__c, soRec);
                        
                        Invoice__c invRec = new Invoice__c();
                        invRec.Name = invWpr.InvoiceNo;
                        invRec.Invoice_Number__c = invWpr.InvoiceNo;
                        invRec.Invoice_Date__c = (invWpr.InvoiceDate != null) ? Date.valueof(invWpr.InvoiceDate) : null;
                        invRec.Invoice_Value__c = (invWpr.Value != null) ? Decimal.valueof(invWpr.Value.replace(' ', '')) : null;
                        invRec.Invoice_Currency__c = invWpr.CurrencyType;
                        invRec.CurrencyIsoCode = invWpr.CurrencyType;
                        invRec.Invoice_Type__c = invWpr.InvoiceType;
                        invRec.Sales_Order__r = new Sales_Order__c(External_Id__c=invWpr.WBS_Id+'_'+invWpr.SalesOrder);
                    	invRec.Sale_Order_Id__c = invWpr.SalesOrder;
                        invRec.WBS__r = new WBS__c(WBS_ID__c=invWpr.WBS_Id);
                    	invRec.WBS_Id__c = invWpr.WBS_Id;
                        invRec.Opportunity__c = invWpr.Opporunity_Id; 
                    	invRec.GL_Account_Description__c = invWpr.GLAccountDesc;
                        invRec.GL_Account_Number__c = invWpr.GLAccount; 
                        if(map_Opportunity.get(invWpr.Opporunity_Id) != null)  invRec.Account__c = map_Opportunity.get(invWpr.Opporunity_Id).AccountID;
                        mapInvoicesToUpsert.put(invRec.Invoice_Number__c, invRec);
                    //}
                }
            }
            
            //DML Operations
            //Upserting WBS
            if(!mapWBStoUpsert.isEmpty()) {
                List<Database.upsertResult> list_WBSResults = Database.upsert(mapWBStoUpsert.values(), WBS__c.WBS_ID__c,false);
                for(Integer i=0;i<list_WBSResults.size();i++) {
                    resOpporutnityWrapper resWbs = new resOpporutnityWrapper();
                    WBS__c wbs = mapWBStoUpsert.values()[i];
                    resWbs.WBS = wbs.WBS_ID__c;
                    resWbs.Id = wbs.Opportunity__c;
                    resWbs.message = '';
                    if (list_WBSResults[i].isSuccess()){
                        resWbs.SF_WBSId = list_WBSResults[i].getId();
                        wbsSuccessCount++;
                    }else{
                        Database.Error err = list_WBSResults.get(i).getErrors().get(0);
                        resWbs.message = 'Error: '+err.getMessage();// + '\nStatus Code : '+err.getStatusCode()+'\n Fields : '+err.getFields();
                        resWbs.message = resWbs.message.replace(Label.WBSSoInvErrorReplace, 'No record found with Id');
                        wbsFailCount++;
                    }
                    resWbs.status = resWbs.message != '' ? 'Failure' : 'Success';
                    resWpr.Opporutnity_Record.add(resWbs);
                }
            }
            //Upserting Sale Order
            if(!mapSOsToUpsert.isEmpty()) { 
                List<Database.upsertResult> list_SO_Results = Database.upsert(mapSOsToUpsert.values(), Sales_Order__c.External_Id__c,false);
                for(Integer i=0;i<list_SO_Results.size();i++) {
                    resSalesWrapper resSo = new resSalesWrapper();
                    Sales_Order__c so = mapSOsToUpsert.values()[i];
                    resSo.SalesOrder = so.Sales_Order_ID__c;
                    resSo.Opporunity_Id = so.Opportunity__c;
                    resSo.WBS = so.WBS_Id__c;
                    resSo.message = '';
                    if (list_SO_Results[i].isSuccess()){
                        resSo.SF_SalesOrder_Id = list_SO_Results[i].getId();
                        soSuccessCount++;
                    }else{
                        Database.Error err = list_SO_Results.get(i).getErrors().get(0);
                        resSo.message = 'Error: '+err.getMessage() + '\nStatus Code : '+err.getStatusCode()+'\n Fields : '+err.getFields();
                        resSo.message = resSo.message.replace(Label.WBSSoInvErrorReplace, 'No record found with Id');
                        soFailCount++;
                    }
                    resSo.status = resSo.message != '' ? 'Failure' : 'Success';
                    resWpr.Sales_Record.add(resSo);
                }
            }
            //Upserting Invoice
            if(!mapInvoicesToUpsert.isEmpty()) { 
                List<Database.upsertResult> list_Inv_Results = Database.upsert(mapInvoicesToUpsert.values(), Invoice__c.Invoice_Number__c,false);
                for(Integer i=0;i<list_Inv_Results.size();i++) {
                    resInvoiceWrapper resInv = new resInvoiceWrapper();
                    Invoice__c inv = mapInvoicesToUpsert.values()[i];
                    resInv.InvoiceNo = inv.Invoice_Number__c;
                    resInv.Opporunity_Id = inv.Opportunity__c;
                    resInv.WBS_Id = inv.WBS_Id__c;
                    resInv.SalesOrder = inv.Sale_Order_Id__c;
                    resInv.GLAccount = inv.GL_Account_Number__c;
                    resInv.GLAccountDesc = inv.GL_Account_Description__c;
                    resInv.message = '';
                    if (list_Inv_Results[i].isSuccess()){
                        resInv.SF_Invoice_Id = list_Inv_Results[i].getId();
                        invSuccessCount++;
                    }else{
                        Database.Error err = list_Inv_Results.get(i).getErrors().get(0);
                        resInv.message = 'Error: '+err.getMessage() + '\nStatus Code : '+err.getStatusCode()+'\n Fields : '+err.getFields();
                        resInv.message = resInv.message.replace(Label.WBSSoInvErrorReplace, 'No record found with Id');
                        invFailCount++;
                    }
                    resInv.status = resInv.message != '' ? 'Failure' : 'Success';
                    resWpr.Invoice_Record.add(resInv);
                }
            }
            
            if(wbsFailCount == 0 && soFailCount == 0 && invFailCount == 0 && wbsSuccessCount == 0 && soSuccessCount == 0 && invSuccessCount == 0){
                dbS.Status__c = 'Failure';
                dbS.Error__c = 'No data has been received';
                resWpr = mapResponse(resWpr, '3', dbS.Status__c, dbS.Error__c);
            }
            else if((wbsFailCount == 0 && soFailCount == 0 && invFailCount == 0) 
                    && (wbsSuccessCount > 0 || soSuccessCount > 0 || invSuccessCount > 0))
            {
                dbS.Status__c = 'Success';
                dbS.Error__c = 'All records have got created/updated successfully';
                resWpr = mapResponse(resWpr, '0', dbS.Status__c, dbS.Error__c);
            }
            else if((wbsFailCount > 0 || soFailCount > 0 || invFailCount > 0)
                    && wbsSuccessCount == 0 && soSuccessCount == 0 && invSuccessCount == 0)
            {
                dbS.Status__c = 'Failure';
                dbS.Error__c = 'All records have failed, check invidual error messages';
                resWpr = mapResponse(resWpr, '2', dbS.Status__c, dbS.Error__c);
            }
            else{
                dbS.Status__c = 'Partial';
                dbS.Error__c = 'Some records have failed, check invidual error messages';
                resWpr = mapResponse(resWpr, '1', dbS.Status__c, dbS.Error__c);
            }
        }catch(exception e){
            dbS.Status__c = 'Failure';
            dbS.Error__c = String.valueOf(e)+'. At: '+e.getStackTraceString();
            resWpr = mapResponse(resWpr, '3', dbS.Status__c, dbS.Error__c);
        }
        Update dbS;
        ContentVersion cVersion = new ContentVersion();
        cVersion.PathOnClient = 'Reponse from Salesforce'+'.txt';
        cVersion.Title = 'Reponse from Salesforce';
        cVersion.FirstPublishLocationId = dbS.Id;
        cVersion.VersionData = Blob.Valueof(Json.serialize(resWpr));
        cVersion.IsMajorVersion = true;
        Insert cVersion;
        return resWpr;
    }
    
    public static WBS__c newWBS(String wbs, String oppId, Map<Id, Opportunity> map_Opportunity){
        WBS__c objWBS = new WBS__c();
        objWBS.Name = wbs;
        objWBS.WBS_ID__c = wbs;
        objWBS.Opportunity__c = oppId;
        if(map_Opportunity.get(oppId) != null)  objWBS.Account__c = map_Opportunity.get(oppId).AccountID;
        return objWBS;
    }
    
    public static Sales_Order__c newSaleOrder(String wbs, String oppId, String soId, String soDate, String cust, String custName, Map<Id, Opportunity> map_Opportunity){
        Sales_Order__c soRec = new Sales_Order__c();
        soRec.Name = soId;
        soRec.Sales_Order_ID__c = soId;
        soRec.External_Id__c = wbs+'_'+soId;
        soRec.WBS__r = new WBS__c(WBS_ID__c=wbs);
        soRec.WBS_Id__c = wbs;
        soRec.Opportunity__c = oppId;
        soRec.Sales_Order_Date__c = (soDate != null) ? Date.valueof(soDate) : null;   
        if(map_Opportunity.get(oppId) != null)  soRec.Account__c = map_Opportunity.get(oppId).AccountID;
        return soRec;
    }    
    
    public static responseWrapper mapResponse(responseWrapper resWpr, String code, String status, String msg){
        resWpr.statusCode = code;
        resWpr.status = status;
        resWpr.message = msg;
        return resWpr;
    }
    
    global class RequestWrapper{
        global List<OpporutnityWrapper> Opporutnity_Record;
        global List<SalesWrapper> Sales_Record;
        global List<InvoiceWrapper> Invoice_Record;
    }
    
    global class OpporutnityWrapper{
        global string ID;
        global string WBS;
    }
    
    global class SalesWrapper{
        global string WBS;
        global string SalesOrder;
        global string Customer;
        global string CustomerName;
        global string SalesOrderDate;
        global string Opporunity_Id;
    }
    
    global class InvoiceWrapper{
        //Request Parameters
        global string SalesOrder;
        global string SalesOrderDate;
        global string Customer;
        global string CustomerName;
        global string InvoiceNo;
        global string InvoiceDate;
        global string CurrencyType;
        global string Value;        
        global string InvoiceType;
        global string WBS_Id;        
        global string Opporunity_Id;
        
        global String GLAccount;
        global String GLAccountDesc;
    }
    
    global class responseWrapper{
        global List<resOpporutnityWrapper> Opporutnity_Record;
        global List<resSalesWrapper> Sales_Record;
        global List<resInvoiceWrapper> Invoice_Record;
        
        global string status;
        global string message;
        global string statusCode;
    }
    
    global class resOpporutnityWrapper{
        global string ID;
        global string WBS;
        
        global string SF_WBSId;
        global string status;
        global string message;
    }
    
    global class resSalesWrapper{
        global string SalesOrder;
        global string Opporunity_Id;
        global string WBS;
        global string SF_SalesOrder_Id;
        global string status;
        global string message;
    }
    
    global class resInvoiceWrapper{
        global string InvoiceNo;
        global string Opporunity_Id;
        global string WBS_Id;
        global String SalesOrder;
        global string SF_Invoice_Id;
        global string status;
        global string message;
        global String GLAccount;
        global String GLAccountDesc;
    }
}