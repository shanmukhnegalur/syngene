/**
*  Purpose         :   This trigger is to handle all the pre and post processing operations for Account object
*
*  Create By       :   Rajeev Jain(PWC)
*
*  Created Date    :   27/12/2018
*
*  Revision Logs   :   V_1.0 - Created
**/ 
trigger Trigger_Account on Account (after insert, after update, before insert, before update,after delete) {
    
    
    //if bypass all triggers is set to true, return without processing
    if (Utility.BYPASS_ALL_TRIGGERS) return; 
    
    if(Trigger.isBefore){
        
        //This flag make sure only Insert and Update Operation handled in trigger
        if(Trigger.isInsert || Trigger.isUpdate){
            Emp_Automate_Geography_Field.geographyFieldUpdateonAccount(trigger.new);
            // AccountTriggerHelper.accountNameCorrection(trigger.new);  
            //UtilityGeographyUpdation.updateGeography(trigger.new);
            
            //ByPass Integration Logic while Customer Account Upload 
            if(Label.ByPass_SAP_Integration == 'false'){
                
                
                TriggerControl__c triggerControl = TriggerControl__c.getOrgDefaults();
                
                if (triggerControl != null && triggerControl.EnableStateCountryValidation__c) {
                    AccountTriggerHelper.validateStateCountryData(Trigger.New, Trigger.OldMap);
                } 
                
                // if(AccountTriggerHelper.isTriggerFired == false){
                if(AccountTriggerHelper.isTriggerFired == false){
                    AccountTriggerHelper.validateSAPFieldValues(Trigger.New, Trigger.OldMap, Trigger.isInsert, Trigger.isUpdate);
                }
            }
            
            AccountTriggerHelper.setMultiSelectPicklistValues(Trigger.New, Trigger.OldMap);
        }
    }   
    if(Trigger.isAfter){
        if(Trigger.isdelete){       
            AccountTriggerHelper.createDeletedAccount(trigger.old);       
        }
        if(Trigger.isInsert || Trigger.isUpdate){
            if(Label.ByPass_SAP_Integration == 'false' && AccountTriggerHelper.isTriggerFired == false){
                
                AccountTriggerHelper.initiateSAPCallout(Trigger.New, Trigger.OldMap, Trigger.isInsert, Trigger.isUpdate);
            }
            List<Account> accountSyncCVMSList = new List<Account>();
            
            for (Account acc : Trigger.new) {
                If(acc.Integrated_with_CVMS__c == false){
                    accountSyncCVMSList.add(acc);
                }
            }
            
            
            if (!accountSyncCVMSList.isEmpty()) {
               System.enqueueJob(new CVMS_AccountSyncQueueable(accountSyncCVMSList));
            } 
        }
    }
}