/**
*  Purpose         :   This class is helper class for trigger on Opportunity object.
*
*  Create By       :   Rajeev Jain(PWC)
*
*  Created Date    :   27/12/2018
*
*  Revision Logs   :   V_1.0 - Created - Syngene CRM Implementation Phase 1
**/ 
public class OpportunityTriggerHelper{
    
    /**
*    @description    :   Method to send reminders to BU heads and Opp owner based on Date bases notification flags
*
*    @Revisions      :   27/12/2018 - Added by - Rajeev Jain(PWC) - Syngene CRM implementation Phase 1
* 
*    @args           :   List of opportunities
* 
*    @return         :   void
* 
**/
    public static void sendReminders(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOppMap ){
        
        //List to Hold the Mails to Be Send
        List<Messaging.SingleEmailMessage> mailsToSend = new List<Messaging.SingleEmailMessage>();
        
        //Set to Hold the Name of the BU head roles.
        Set<String> roles = new Set<String>();
        
        //List to Hold the Opportunities applicable for Close Date Notification
        List<Opportunity> oppsForCloseNotifcation = new List<Opportunity>();
        
        //List to Hold the Opportunities applicable for Close Date Notification
        List<Opportunity> oppsForProposalSubNotifcation = new List<Opportunity>();
        
        //Get Opportunities Fields which contains BU values
        List<Schema.FieldSetMember> buFields = Utility.getFieldDetails('BUFields', 'Opportunity');
        
        for(Opportunity opp : newOpportunities){
            
            //Send Close Date Notification
            if((oldOppMap == null && (opp.First_Close_Date_Notification__c || opp.Second_Close_Date_Notification__c)) || 
               (oldOppMap != null && 
                (
                    (opp.First_Close_Date_Notification__c != oldOppMap.get(opp.Id).First_Close_Date_Notification__c && opp.First_Close_Date_Notification__c) || 
                    (opp.Second_Close_Date_Notification__c != oldOppMap.get(opp.Id).Second_Close_Date_Notification__c && opp.Second_Close_Date_Notification__c)
                )
               )
              ){
                  
                  //Populate BU Roles at runtime dynamically
                  roles.addAll(Utility.getBURoles(buFields, opp));
                  
                  if(opp.StageName != 'Lost') oppsForCloseNotifcation.add(opp);
              }
            
            //Send Proposal Submission Date Reminder Notification
            if((oldOppMap == null && (opp.First_Proposal_Submission_Date_Notificat__c || opp.Second_Proposal_Submission_Date_Notifica__c)) || 
               (oldOppMap != null && 
                (
                    (opp.First_Proposal_Submission_Date_Notificat__c != oldOppMap.get(opp.Id).First_Proposal_Submission_Date_Notificat__c && opp.First_Proposal_Submission_Date_Notificat__c) || 
                    (opp.Second_Proposal_Submission_Date_Notifica__c != oldOppMap.get(opp.Id).Second_Proposal_Submission_Date_Notifica__c && opp.Second_Proposal_Submission_Date_Notifica__c)
                )
               )
              ){
                  
                  //Populate BU Roles at run time dynamically
                  roles.addAll(Utility.getBURoles(buFields, opp));
                  
                  oppsForProposalSubNotifcation.add(opp);
              }
        }
        
        //Map to Hold the Assigned User corrosponding to Each Role
        Map<String, List<User>> mapRoleWithUsers = Utility.getRolesWithUsers(roles);
        
        if(oppsForCloseNotifcation.size() > 0){
            
            String templateId = Constant.CLOSE_DATE_REMINDER_TEMPLATE_ID;
            
            Utility.processMailToSentList(oppsForCloseNotifcation, mailsToSend, mapRoleWithUsers, templateId, buFields, 'Opportunity');
        }
        
        if(oppsForProposalSubNotifcation.size() > 0){
            
            String templateId = Constant.PROPOSAL_SUBMISSION_DATE_REMINDER_TEMPLATE_ID;
            
            Utility.processMailToSentList(oppsForProposalSubNotifcation, mailsToSend, mapRoleWithUsers, templateId, buFields, 'Opportunity');
        }
    }
   
    /**
*    @description    :   Method to populate multi-select picklist
*
*    @Revisions      :   18/02/2019 - Added by - Madhurima(PWC) - Syngene CRM implementation Phase 1
* 
*    @args           :   List of Accounts, and Map of Old Accounts
* 
*    @return         :   void
* 
**/
    public static void setMultiSelectPicklistValues(List<Opportunity> opportunities, Map<Id, Opportunity> oldOpportunitiesMap){
        Utility.saveMultiselectPicklist(opportunities, oldOpportunitiesMap);
    }
    
    //below code is added to create a copy of deleted opportunities
    //and add them in Blocked_Opportunity__c table
    
    public static void createDeletedOpportunity(List<Opportunity> OpportunityList){
        List<Blocked_Opportunity__c> deletedOpportunityList = new List<Blocked_Opportunity__c>();
        for(Opportunity o :OpportunityList){
            Blocked_Opportunity__c bo = new Blocked_Opportunity__c();
            bo.Name=o.Name;
            bo.Account_Name__c=o.AccountId;
            bo.Bioinformatics__c=o.Bioinformatics__c;
            bo.Biologics__c=o.Biologics__c;
            bo.Biologics1__c=o.Biologics1__c;
            bo.Budgetory__c=o.Budgetory__c;
            bo.Business_Model__c=o.Business_Model__c;
            bo.Business_Reversal__c=o.Business_Reversal__c;
            bo.Business_Type__c=o.Business_Type__c;
            //bo.Business_Type_URL__c=o.Business_Type_URL__c;
            bo.Chemical_Development__c=o.Chemical_Development__c;
            bo.Clinical_Development__c=o.Clinical_Development__c;
            bo.Clinical_Development1__c=o.Clinical_Development1__c;
            bo.Close_Date__c=o.CloseDate;
            //bo.CommentsStatus__c=o.WIP_Comments_Status__c;
            //bo.Comments_Status__c=o.WIP_Comments_Status__c;
            bo.Contact__c=o.Contact__c;
            bo.CurrencyIsoCode=o.CurrencyIsoCode;
            bo.Current_FY__c=o.Current_FY__c;
            bo.Current_FY_1__c=o.Current_FY_1__c;
            bo.Current_FY_2__c=o.Current_FY_2__c;
            bo.Current_FY_3__c=o.Current_FY_3__c;
            bo.Current_FY_4__c=o.Current_FY_4__c;
            bo.Deleted_Opportunity_ID__c=o.Complete_Opportunity_ID__c;
            bo.Description__c=o.Description;
            bo.Detailed_WinLoss_Reason_for_Others__c=o.Detailed_Win_Loss_Reason_for_Others__c;
            bo.Development__c=o.Development__c;
            bo.Discovery__c=o.Discovery__c;
            bo.Discovery_Biology__c=o.Discovery_Biology__c;
            bo.Discovery_Chemistry__c=o.Discovery_Chemistry__c;
            bo.Expected_Revenue_Current_FY__c=o.Expected_Revenue_Current_FY__c;
            bo.Expected_Revenue_Current_FY_1__c=o.Expected_Revenue_Current_FY_1__c;
            bo.Expected_Revenue_Current_FY_2__c=o.Expected_Revenue_Current_FY_2__c;
            bo.Expected_Revenue_Current_FY_3__c=o.Expected_Revenue_Current_FY_3__c;
            bo.Expected_Revenue_Current_FY_4__c=o.Expected_Revenue_Current_FY_4__c;
            bo.Expected_Revenue_In_Current_FY__c=o.ExpectedRevenue;
            bo.Final_Version_In_Date__c=o.Final_Version_In_Date__c;
            bo.Final_Version_Submitted_Date__c=o.Final_Version_Submitted_Date__c;
            bo.First_Version_Submitted_Date__c=o.First_Version_Submitted_Date__c;
            bo.Formulation__c=o.Formulation__c;
            bo.FTE_Rate__c=o.FTE_Rate__c;
            bo.FTE_Weeks__c=o.FTE_Weeks__c;
            //bo.Is_this_IDD__c=o.Is_this_IDD__c;
            bo.Is_this_Integrated_CMC__c=o.Is_this_CMC__c;
            bo.Lead_Subject__c=o.Lead_Subject__c;
            //bo.LinkedIn_Company_Id__c=o.LID__LinkedIn_Company_Id__c;
            bo.Lost_Reason__c=o.Lost_Reason__c;
            bo.Next_Step__c=o.NextStep;
            //bo.Number_of_FTEs__c=o.Number_of_FTEs__c;
            //bo.Previous_Stage__c=o.Current_Stage__c;
            //bo.Probability__c=o.Probability;
            bo.Proposal_Submission_Date__c=o.Proposal_Submission_Date__c;
            bo.Parent_Opportunity__c = o.Parent_Opportunity__c;
            bo.Reversal_Date__c=o.Reversal_Date__c;
            bo.Record_Type_Id__c = o.RecordTypeId;
            bo.Reversal_Value__c=o.Reversal_Value__c;
            bo.Reviewed_By__c=o.Reviewed_By__c;
            bo.RFx_Team_Engagement_Required__c=o.RFx_Team_Engagement_Required__c;
            //bo.RFP_Final_Version_TAT__c=o.RFP_Final_Version_TAT__c;
            //bo.RFP_First_Version_TAT__c=o.RFP_TAT__c;
            bo.RFP_In_Date__c=o.RFP_In_Date__c;
            bo.RFP_Status__c=o.RFP_Status__c;
            bo.RFX_Team_Member__c=o.RFX_Team_Member__c;
            //bo.RM_Cost__c=o.RM_Cost__c;
            bo.Safety_Assessment__c=o.Safety_Assessment__c;
            bo.Sole_Source__c=o.Sole_Source__c;
            bo.Stability__c=o.Stability__c;
            bo.StageName__c=o.StageName;
            bo.Stages__c=o.Stages__c;
            bo.Opportunity_Value__c=o.Amount;
            bo.Verbal_Commitment__c=o.Verbal_Commitment__c;
            bo.Who_Lost_To__c=o.Who_Lost_To__c;
            bo.Win_Reason__c=o.Win_Reason__c;
            bo.Won_Against__c=o.Won_Against__c;
            bo.Last_Stage_Change_Date__c=o.Last_Stage_Change_Date__c;//Added on 12/06/2020 for stage duration.
            bo.Primary_Lost_Reason__c=o.Primary_Lost_Reason__c;
            bo.Primary_Win_Reason__c=o.Primary_Win_Reason__c;
            bo.Sub_Primary_Lost_Reason__c=o.Sub_Primary_Lost_Reason__c;
            bo.Sub_Primary_Win_Reason__c=o.Sub_Primary_Win_Reason__c;
            bo.Secondary_Lost_Reason__c=o.Secondary_Lost_Reason__c;
            bo.Secondary_Win_Reason__c=o.Secondary_Win_Reason__c;
            bo.Sub_Secondary_Lost_Reason__c=o.Sub_Secondary_Lost_Reason__c;
            bo.Sub_Secondary_Win_Reason__c=o.Sub_Secondary_Win_Reason__c;//Till here
            bo.Helped_close_the_Opportunity__c=o.Helped_close_the_Opportunity__c;
            bo.Budgetary_Proposal__c=o.Budgetary_Proposal__c;
            bo.Proposal_compliant_with_pricing_policy__c=o.Proposal_compliant_with_pricing_policy__c;
            bo.Do_you_have_approvals_per_pricing_policy__c=o.Do_you_have_approvals_per_pricing_policy__c;
            bo.Therapeutic_area__c=o.Therapeutic_area__c;
            bo.Phases__c=o.Phases__c;
            bo.Sales_Stage_Backtracking_Reason__c=o.Sales_Stage_Backtracking_Reason__c;
            bo.Latest_Quote__c = o.Latest_Quote__c;
            bo.Allow_Confident_Verbal_Contracting_Stage__c = o.Allow_Confident_Verbal_Contracting_Stage__c;
            bo.Opportunity_reference_name_for_survey__c=o.Opportunity_reference_name_for_survey__c;
            bo.Opt_out_of_Survey__c=o.Opt_out_of_Survey__c;
            bo.Reason_To_Opt_out_of_Survey__c=o.Reason_To_Opt_out_of_Survey__c;
            bo.Opt_out_of_Survey_at__c=o.Opt_out_of_Survey_at__c;
            bo.SynVent_Dropdown__c = o.SynVent_Dropdown__c;
            bo.Business_Unit__c = o.Business_Unit__c;
            deletedOpportunityList.add(bo);
        }
        if(deletedOpportunityList.size()>0){
            insert deletedOpportunityList;
        }
        
    }
    
    public static void rollup(List<opportunity> opportunities){
        
        List<id> accIdList = new List<id>();
        For(opportunity opp1 : opportunities){
            accIdList.add(opp1.AccountId);
        }
        List<Account> accUpdateList = new List<Account>();
        For(Account acc : [SELECT Number_Of_Opportunities__c,(SELECT id FROM opportunities) FROM Account WHERE id =: accIdList]){
            acc.Number_Of_Opportunities__c = acc.opportunities.size();
            accUpdateList.add(acc);
        }
        //try{
        update accUpdateList;
        //}Catch(Exception e){
        // System.debug('Exception :'+e.getMessage());
        // }
    }
}