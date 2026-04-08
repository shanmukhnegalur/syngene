/**
 *  Purpose         :   This trigger is to handle all the pre and post processing operations for Opportunity object
 *
 *  Create By       :   Rajeev Jain(PWC)
 *
 *  Created Date    :   27/12/2018
 *
 *  Revision Logs   :   V_1.0 - Created
**/ 
trigger Trigger_Opportunity on Opportunity (after insert, after update, before insert, before update,After delete,After undelete) {
    
    //if bypass all triggers is set to true, return without processing
    if (Utility.BYPASS_ALL_TRIGGERS) return; 
    
    //This flag make sure to Run only After Context of the Trigger
    if(Trigger.isAfter)
    {
        
        //This flag make sure only Insert and Update Operation handled in trigger
        if(Trigger.isInsert || Trigger.isUpdate){
            
            //Pass New Data in Case of Insert operation
            //Pass Both new and Old data in case of Update operation
            OpportunityTriggerHelper.sendReminders(Trigger.New, Trigger.OldMap);
            if(Trigger.isInsert)//Add contactrole on 26/06/2020
            {
                CreateNewContactRoles.contactrolewhenopportunityinserts(Trigger.New);
               // OppItemsDCBCreation.OppItemsCrtn(trigger.new, null);
                  List<Opportunity> newOpportunities = new List<Opportunity>();

                for (Opportunity opp : Trigger.New) {

                    if (opp.StageName != null && opp.Contact__c != null) {

                        newOpportunities.add(opp);

                    }

                }

                if ((!newOpportunities.isEmpty() && LinkedInHelper.isTriggerFired == false) || Test.isRunningTest()) {

                    LinkedInHelper.processOpportunities(newOpportunities);

                }
            }
            if(Trigger.isUpdate)
            {
                CreateNewContactRoles.contactrolewhenopportunityupdates(Trigger.New, Trigger.OldMap);
               // OppItemsDCBCreation.OppItemsCrtn(trigger.new, trigger.oldmap);
                  List<Opportunity> wonOpportunities = new List<Opportunity>();

                for (Opportunity opp : Trigger.New) {

                    if ( Trigger.oldMap.get(opp.Id).StageName != opp.StageName && opp.Contact__c != null ) {

                        wonOpportunities.add(opp);

                    } 

                }


                if ((!wonOpportunities.isEmpty() && LinkedInHelper.isTriggerFired == false )|| Test.isRunningTest()) {

                    LinkedInHelper.processOpportunities(wonOpportunities);

                }

            }//Till here
            
        }
        //Added for Creating Milestones regarding Salesforecasting - by Vijaya Amarnath (ePeople)   
        if(Trigger.IsInsert){   
            //SFCAST_MilestoneCreation.createMilestones_new(Trigger.New);   
            //UpdateMilestonesDate.MilestonesDateUpdateMethod(Trigger.New, Null);   
                
        }   
         if(Trigger.IsUpdate){   
            //SFCAST_MilestoneCreation.createMilestonesOnUpdate(Trigger.New,Trigger.OldMap);    
            //UpdateMilestonesDate.MilestonesDateUpdateMethod(Trigger.New, Trigger.OldMap); 
            // sending data to digital layer when StageName changed to Price Sheetazure system shrijak
        if (OpporunityAzureIntegrationHandler.isExecuted) {
        System.debug('Trigger already executed, skipping this run.');
        return;
    }
    	OpporunityAzureIntegrationHandler.isExecuted = true;
  		System.debug('Trigger run.');
   		 OpporunityAzureIntegrationHandler.processOpportunities(Trigger.new, Trigger.oldMap);
   		 System.debug('Trigger  executed, ');
        }
    }
    if(Trigger.isBefore){
         //This flag make sure only Insert and Update Operation handled in trigger
        if(Trigger.isInsert || Trigger.isUpdate){            
            //Pass Trigger Context data in Helper method
            //Utility.validateMultiselectServiceInterests(Trigger.New, Trigger.OldMap);
            OpportunityTriggerHelper.setMultiSelectPicklistValues(Trigger.New, Trigger.OldMap);
            //Method for SalesPipeLineLeakageUpdate
            SalesPipeLineLeakageUpdate.updateProgressing(Trigger.OldMap,Trigger.New);
            OpportunityBusinessTypeCalculation.businesstypecalculation(Trigger.New);    
            OpportunityTargetMapping.mapTargetId(Trigger.New, Trigger.OldMap);
        }
        if(Trigger.isUpdate){
            OpportunityTriggerHelperV1.opportunityRecordLock(Trigger.New,Trigger.OldMap);
            OpportunityTriggerHelperV1.opportunityRecordLockRFXUser(Trigger.New,Trigger.OldMap);
            CheckFileisAttached.attachmentcheck(Trigger.New);
          //  OpportunityTriggerHelper.setMultiSelectPicklistValues(Trigger.New, Trigger.OldMap);
          //  SalesPipeLineLeakageUpdate.updateProgressing(Trigger.OldMap,Trigger.New);
        }
        /*if(Trigger.isUpdate){
            SalesPipeLineLeakageUpdate.updateProgressing(Trigger.OldMap,Trigger.New);
        }*/
        
    } 
    
    

    
    
   /* if(Trigger.isAfter){
        
        if(trigger.isInsert || Trigger.isUndelete ||Trigger.isupdate){
            
            OpportunityTriggerHelper.rollup(trigger.new);
            
        }
        if(Trigger.isDelete){
            OpportunityTriggerHelper.rollup(trigger.old);
        }
        
    }*/
    
    if(Trigger.isAfter){
        if(Trigger.isdelete){
            
           OpportunityTriggerHelper.createDeletedOpportunity(trigger.old);
            
        }
    } 
    
   /*  if (Trigger.isAfter && Trigger.isUpdate) {  
       
        Set<Id> oppIdsToProcess = new Set<Id>();
  
        for (Opportunity opp : Trigger.new) {  
            Opportunity oldOpp = Trigger.oldMap.get(opp.Id);  
            // Check if the stage has changed to "Price Sheet Preparation"  
            if (opp.StageName == 'Price Sheet Preparation' && oldOpp.StageName != 'Price Sheet Preparation') {  
                oppIdsToProcess.add(opp.Id); 
            }  
        }  
  
        if (!oppIdsToProcess.isEmpty()) {  
          
                OpporunityAzureIntegrationHandler.sendOppData(new List<Id>(oppIdsToProcess));
           
        }  
    }  
     
       // Loop through each Opportunity in the trigger  
    for (Opportunity opp : Trigger.new) {  
        // Handle both insert and update scenarios  
        Boolean isPriceSheetPreparationStage = opp.StageName == 'Price Sheet Preparation';  
  
        // Check for newly inserted opportunities with the stage 'Price Sheet Preparation'  
        if (Trigger.isInsert && isPriceSheetPreparationStage) {  
            oppIdsToProcess.add(opp.Id);  
        }  
        // Check for updated opportunities where the stage has changed to 'Price Sheet Preparation'  
        else if (Trigger.isUpdate && isPriceSheetPreparationStage &&  
                 opp.StageName != Trigger.oldMap.get(opp.Id).StageName) {  
            oppIdsToProcess.add(opp.Id);  
        }  
    }  
  
    if (!oppIdsToProcess.isEmpty()) {  
        OpporunityAzureIntegrationHandler.sendOppData(oppIdsToProcess);  
    }  */
     
}