/**
*  Purpose         :   This trigger is to handle all the pre and post processing operations for Contact object
*
*  Create By       :   Rajeev Jain(PWC)
*
*  Created Date    :   27/12/2018
*
*  Revision Logs   :   V_1.0 - Created
**/ 
trigger Trigger_Contact on Contact (after insert, after update, before insert, before update,after delete, after undelete) {
    
    
    //if bypass all triggers is set to true, return without processing
    if (Utility.BYPASS_ALL_TRIGGERS) return; 
    
    if(Trigger.isBefore){
        
        //This flag make sure only Insert and Update Operation handled in trigger
        if(Trigger.isInsert || Trigger.isUpdate){
            Emp_Automate_Geography_Field.geographyFieldUpdateonContact(trigger.new);
            // CountContactsAndOpportinties.CountContacts(trigger.new,trigger.old);
            
            // below line of code is written for AI-00028
            //UtilityGeographyUpdation.updateGeography(trigger.new);
            
            //Pass Trigger Context data in Helper method
            //Utility.validateMultiselectServiceInterests(Trigger.New, Trigger.OldMap);
            //Utility.updateMarketingHead(Trigger.New);
            
            ContactTriggerHelper.updateMarketingHeadOnContact(Trigger.New, Trigger.OldMap);
            ContactTriggerHelper.setMultiSelectPicklistValues(Trigger.New, Trigger.OldMap);
        }
    }
    
    /* if(Trigger.isAfter){       
if(trigger.isInsert || Trigger.isUndelete || Trigger.isUpdate){  
ContactTriggerHelper.rollup(trigger.new);  
}
if(Trigger.isDelete){
ContactTriggerHelper.rollup(trigger.old);
ContactTriggerHelper.createblockedcontact(trigger.old);
}
} */
    if(Trigger.IsAfter)
    {
        if(trigger.IsInsert)  { 
            ContactTriggerHelper.RollupNoofContacts(Trigger.new,null);
            system.debug('emtering LinkedInHelper contacts');
            //LinkedInHelper.processContacts(Trigger.new);
            //
            List<Contact> contactsWithAccountInfo = [SELECT Id, FirstName, LastName, Email, Title, MailingCountryCode, AccountId, Account.Name,
                                                     Integrated_with_LinkedIn__c
                                                     FROM Contact 
                                                     WHERE Id IN :Trigger.new AND Integrated_with_LinkedIn__c = FALSE];
            
            LinkedInHelper.processContacts(contactsWithAccountInfo); 
            List<Contact> contactSyncCVMSList = new List<Contact>();
            for(Contact con:Trigger.New){
                If(con.Integrated_with_CVMS__c == false){
                    contactSyncCVMSList.add(con);
                }
            }
            if (!contactSyncCVMSList.isEmpty()) {
                System.enqueueJob(new CVMS_ContactSyncQueueable(contactSyncCVMSList));
            } 
        }
        if(trigger.IsUpdate) {
            ContactTriggerHelper.RollupNoofContacts(Trigger.new,Trigger.oldmap);
            List<Contact> contactSyncCVMSList = new List<Contact>();
            for(Contact con:Trigger.New){
                If(con.Integrated_with_CVMS__c == false){
                    contactSyncCVMSList.add(con);
                }
            }
            if (!contactSyncCVMSList.isEmpty()) {
                System.enqueueJob(new CVMS_ContactSyncQueueable(contactSyncCVMSList));
            } 
        }
        if(trigger.IsDelete) {
            ContactTriggerHelper.RollupNoofContacts(Trigger.old,null);
            ContactTriggerHelper.createblockedcontact(trigger.old);
        }
        if(trigger.IsUnDelete) {  ContactTriggerHelper.RollupNoofContacts(Trigger.new,null); }
    }
}