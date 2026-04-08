public class InvoiceTriggerHandler 
{
    /* Public static void RollUpInvoiceAmount(List<Invoice__c> newInvoiceList)
{
Set<Id> setOppIds = new Set<Id>();
Map<Id,Opportunity> mapOpp = new Map<Id,Opportunity>();

for(Invoice__c objInvoiceRecord : newInvoiceList)
{
if(objInvoiceRecord.Opportunity__c != null && objInvoiceRecord.Invoice_Value__c != null)
{
setOppIds.add(objInvoiceRecord.Opportunity__c);
}
}

if(!setOppIds.IsEmpty())
{
for(Id oppId : setOppIds)
{
mapOpp.put(oppId,new Opportunity(Id=oppId,Total_Invoice_Value__c = 0,Invoice_Record_Count__c =0));
}
for(Invoice__c objAllInvoices : [SELECT ID,Name,Invoice_Value__c,Opportunity__c
FROM Invoice__c
WHERE Opportunity__c IN :setOppIds])
{
if(mapOpp.get(objAllInvoices.Opportunity__c)!= Null && objAllInvoices.Invoice_Value__c != null)
{
mapOpp.get(objAllInvoices.Opportunity__c).Total_Invoice_Value__c = mapOpp.get(objAllInvoices.Opportunity__c).Total_Invoice_Value__c + objAllInvoices.Invoice_Value__c;
mapOpp.get(objAllInvoices.Opportunity__c).Invoice_Record_Count__c = mapOpp.get(objAllInvoices.Opportunity__c).Invoice_Record_Count__c + 1;
}
}

if(!mapOpp.IsEmpty())
Update mapOpp.Values();
}
}*/
    public static void RollUpInvoiceAmount(List<Invoice__c> newInvoiceList){
        Set<Id> setOppIds = new Set<Id>();
        Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity>();
        List<String> lstSaleTypes = Label.SalesInvoiceNumbers.split(',');
        List<String> lstPassThrough = Label.PassThroughInvoiceNumbers.split(',');
        
        for(Invoice__c inv : newInvoiceList){
            if(inv.Opportunity__c != null && inv.Invoice_Value__c != null &&
                (lstSaleTypes.contains(inv.GL_Account_Number__c) || lstPassThrough.contains(inv.GL_Account_Number__c))){
                    setOppIds.add(inv.Opportunity__c);
                }
        }
        
        if(!setOppIds.isEmpty()){
            
            for(Id oppId : setOppIds){
                mapOpp.put(oppId, new Opportunity(Id = oppId, Total_Invoice_Value__c = 0,Credit_Memo_Invoice_Value__c = 0,
                                                  Cancellation_Invoice_Value__c = 0, Invoice_Record_Count__c = 0,
                                                  PT_Invoice_Record_Count__c=0,PT_Total_Invoice_Value__c=0,
                                                  PT_Credit_Memo_Invoice_Value__c=0,PT_Cancellation_Invoice_Value__c=0));
            }
            
            for(Invoice__c inv : [SELECT Id, Name, Invoice_Value__c, Opportunity__c, Invoice_Type__c,GL_Account_Number__c FROM Invoice__c
                                   WHERE Opportunity__c IN :setOppIds AND (GL_Account_Number__c IN: lstSaleTypes OR GL_Account_Number__c IN: lstPassThrough)])
                
            {
                Opportunity opp = mapOpp.get(inv.Opportunity__c);
                if (opp != null && inv.Invoice_Value__c != null){
                    String invType = inv.Invoice_Type__c != null ? inv.Invoice_Type__c.trim().toLowerCase() : '';
                    if(lstSaleTypes.contains(inv.GL_Account_Number__c)){
                        if(invType == 'invoice'){
                            opp.Total_Invoice_Value__c += inv.Invoice_Value__c;
                        }
                        else if(invType == 'credit memo'){
                            opp.Credit_Memo_Invoice_Value__c += inv.Invoice_Value__c;
                        }
                        else if(invType == 'invoice cancellation'){
                            opp.Cancellation_Invoice_Value__c += inv.Invoice_Value__c;
                        }
                        opp.Invoice_Record_Count__c += 1;
                    }else{
                        if(invType == 'invoice'){
                            opp.PT_Total_Invoice_Value__c += inv.Invoice_Value__c;
                        }
                        else if(invType == 'credit memo'){
                            opp.PT_Credit_Memo_Invoice_Value__c += inv.Invoice_Value__c;
                        }
                        else if(invType == 'invoice cancellation'){
                            opp.PT_Cancellation_Invoice_Value__c += inv.Invoice_Value__c;
                        }
                        opp.PT_Invoice_Record_Count__c += 1;
                    }
                }
            }
            
            if(!mapOpp.isEmpty()){
                update mapOpp.values();
            }
        }
    }
    
    
    Public static void UpdateProjectInInvoice(List<Invoice__c> newInvoiceList)
    {
        Set<Id> setOppIds = new Set<Id>();
        
        for(Invoice__c objInvoiceRecord : newInvoiceList)
        {
            if(objInvoiceRecord.Opportunity__c != null && objInvoiceRecord.Project__c == null)
            {
                setOppIds.add(objInvoiceRecord.Opportunity__c);
            }
        }
        
        if(!setOppIds.isEmpty())
        {
            Map<Id,Project__c> mapProjects = new Map<Id,Project__c>();
            //List<Invoice__c> listUpdateInvoices = new List<Invoice__c>();
            
            for(Project__c objProject : [SELECT ID,Name,Complete_Opportunity_Id__c 
                                         FROM Project__c
                                         WHERE Complete_Opportunity_Id__c IN :setOppIds])
            {
                mapProjects.put(objProject.Complete_Opportunity_Id__c,objProject);
            }
            
            if(!mapProjects.isEmpty())
            {
                for(Invoice__c objInvoiceRecord : newInvoiceList)
                {
                    if(objInvoiceRecord.Project__c == null)
                    {  
                        if(mapProjects.get(objInvoiceRecord.Opportunity__c) != null)
                        {
                            objInvoiceRecord.Project__c = mapProjects.get(objInvoiceRecord.Opportunity__c).Id;
                        }
                    }
                }
                
                /*for(Invoice__c objAllInvoices : [SELECT ID,Name,Invoice_Value__c,Opportunity__c,Project__c
FROM Invoice__c
WHERE Opportunity__c IN :setOppIds])
{
if(mapProjects.get(objAllInvoices.Opportunity__c) != null)
{
objAllInvoices.Project__c = mapProjects.get(objAllInvoices.Opportunity__c).Id;
listUpdateInvoices.add(objAllInvoices);
}
}

if(!listUpdateInvoices.isEmpty())
Update listUpdateInvoices;*/
            }
        }
    }
}