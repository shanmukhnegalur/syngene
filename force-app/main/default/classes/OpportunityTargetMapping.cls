/*************************************************************
@Name: OpportunityTargetMapping
@Author: Forsys Team
@Description: Input Data for Opportunity Object  to use in the test classes.
******************************************************************/
public without sharing class OpportunityTargetMapping {
    
    
    public static void mapTargetId(List<Opportunity> lst_Opp, map<Id,Opportunity> map_Opp)
    {
        set<Id> set_OppownerIds = new set<Id>();
        set<string> set_ClosedMonth = new set<string>();
        set<string> set_Division = new set<string>();
        set<string> set_operationUnit = new set<string>();
        if(map_Opp == null) {
            for(Opportunity objOpp : lst_Opp)
            {                
                if(objOpp.StageName == 'Win') {
                    set_OppownerIds.add(objOpp.ownerid);
                    String closedMonth = calculateClosedMonth(objOpp.CloseDate);
                    set_ClosedMonth.add(closedMonth);
                    //set_ClosedMonth.add(objOpp.Closed_Month__c);
                    if(objOpp.Is_this_SynVent__c == 'Yes' && objOpp.Discovery__c == true)
                    {
                        set_Division.add('Discovery');
                        set_operationUnit.add('SynVent');
                    }
                    else if(objOpp.MSEZ__c == 'MSEZ' && objOpp.Development__c == true){
                        set_Division.add('Development');
                        set_operationUnit.add('MSEZ');
                    }
                    else{
                        if(objOpp.Discovery__c == true) {
                            set_Division.add('Discovery');  
                            
                            if(objOpp.Discovery_Biology__c != null)
                            {
                                set_operationUnit.add('Discovery Biology');
                            }
                            else if(objOpp.Discovery_Chemistry__c != null)
                            {
                                set_operationUnit.add('Discovery Chemistry');
                            }
                            else if(objOpp.Safety_Assessment__c != null)
                            {
                                set_operationUnit.add('Safety Assessment');
                            }
                            else if(objOpp.Bioinformatics__c != null)
                            {
                                set_operationUnit.add('Computational and Data Sciences');
                            }
                            
                        }
                        if(objOpp.Biologics__c == true) {
                            set_Division.add('Biologics');  
                            if(objOpp.Biologics1__c!= null)
                            {
                                set_operationUnit.add('Biologics');
                            }
                            
                        }
                        if(objOpp.Development__c == true) {
                            set_Division.add('Development');
                            if(objOpp.Chemical_Development__c != null)
                            {
                                set_operationUnit.add('Chemical Development');
                            }
                            else if(objOpp.Formulation__c != null)
                            {
                                set_operationUnit.add('Formulation');
                            }
                            else if(objOpp.Stability__c != null)
                            {
                                set_operationUnit.add('Analytical Development');
                            }
                        }    
                        if(objOpp.Clinical_Development__c == true) {
                            set_Division.add('Translational & Clinical Research (T&CR)');
                            if(objOpp.Clinical_Development1__c != null)
                            {
                                set_operationUnit.add('Translational & Clinical Research (T&CR)');
                            }
                        }            
                    }
                    
                }
            }
        }
        else if(map_Opp != null )
        {
            for(Opportunity objOpp : lst_Opp)
            {
                
                if(map_Opp.containskey(objOpp.Id) && map_Opp.get(objOpp.Id).StageName !=  objOpp.StageName && objOpp.StageName == 'Win'
                   || (map_Opp.containskey(objOpp.Id) && map_Opp.get(objOpp.Id).OwnerId !=objOpp.OwnerId && objOpp.StageName == 'Win')) {
                       set_OppownerIds.add(objOpp.ownerid);
                       
                       String closedMonth = calculateClosedMonth(objOpp.CloseDate);
                       set_ClosedMonth.add(closedMonth);
                       //set_ClosedMonth.add(objOpp.Closed_Month__c);
                       
                       if(objOpp.Is_this_SynVent__c == 'Yes' && objOpp.Discovery__c == true)
                       {
                           set_Division.add('Discovery');
                           set_operationUnit.add('SynVent');
                       }
                       else if(objOpp.MSEZ__c == 'MSEZ' && objOpp.Development__c == true){
                           set_Division.add('Development');
                           set_operationUnit.add('MSEZ');
                       }
                       else{
                           if(objOpp.Discovery__c == true){
                               set_Division.add('Discovery');
                               if(objOpp.Discovery_Biology__c != null)
                               {
                                   set_operationUnit.add('Discovery Biology');
                               }
                               else if(objOpp.Discovery_Chemistry__c != null)
                               {
                                   set_operationUnit.add('Discovery Chemistry');
                               }
                               else if(objOpp.Safety_Assessment__c != null)
                               {
                                   set_operationUnit.add('Safety Assessment');
                               }
                               else if(objOpp.Bioinformatics__c != null)
                               {
                                   set_operationUnit.add('Computational and Data Sciences');
                               }
                           }    
                           if(objOpp.Biologics__c == true){
                               set_Division.add('Biologics');
                               if(objOpp.Biologics1__c!= null)
                               {
                                   set_operationUnit.add('Biologics');
                               }
                           }      
                           if(objOpp.Development__c == true){
                               set_Division.add('Development');
                               if(objOpp.Chemical_Development__c != null)
                               {
                                   set_operationUnit.add('Chemical Development');
                               }
                               else if(objOpp.Formulation__c != null)
                               {
                                   set_operationUnit.add('Formulation');
                               }
                               else if(objOpp.Stability__c != null)
                               {
                                   
                                   set_operationUnit.add('Analytical Development');
                               }
                           }    
                           if(objOpp.Clinical_Development__c == true){
                               set_Division.add('Translational & Clinical Research (T&CR)');
                               if(objOpp.Clinical_Development1__c != null)
                               {
                                   set_operationUnit.add('Translational & Clinical Research (T&CR)');
                               }
                           }    
                       }
                       
                   }
            }
        }
        if(Test.isRunningTest()){
            set_ClosedMonth.add('None');
        }
        //system.debug('=====>>>>set_Division '+ set_Division + set_OppownerIds + set_ClosedMonth+set_operationUnit);
        map<string,Target__c> map_Target = new map<string,Target__c>();        
        for(Target__c objTarget : [select Id,Division__c,OwnerId,Target_Month__c,Target_Year__c,Operating_Unit__c from Target__c where Division__c IN: set_Division AND Operating_Unit__c IN:set_operationUnit and OwnerId IN: set_OppownerIds and Target_Month__c IN: set_ClosedMonth])
        {
            //system.debug('=====>>>>Map '+map_Target);
            if(!map_Target.ContainsKey(objTarget.OwnerId+objTarget.Target_Month__c+objTarget.Target_Year__c+objTarget.Division__c+objTarget.Operating_Unit__c))
                map_Target.put(objTarget.OwnerId+objTarget.Target_Month__c+objTarget.Target_Year__c+objTarget.Division__c+objTarget.Operating_Unit__c, objTarget);
        }
        //system.debug('=====>>>>Map '+map_Target.Values());
        if(map_Target.size() > 0)
        {
            for(Opportunity objOpp : lst_Opp)
            {
                string str_Division;
                string str_OperatingUnit;
                if(objOpp.Is_this_SynVent__c == 'Yes' && objOpp.Discovery__c == true)
                {
                    str_Division = 'Discovery';
                    str_OperatingUnit = 'SynVent';
                }
                else if(objOpp.MSEZ__c == 'MSEZ' && objOpp.Development__c == true){
                    
                    str_Division = 'Development';
                    str_OperatingUnit = 'MSEZ';
                    
                }
                else {
                    if(objOpp.Discovery__c == true){
                        str_Division = 'Discovery';
                        if(objOpp.Discovery_Biology__c != null)
                        {
                            str_OperatingUnit = 'Discovery Biology';
                        }
                        else if(objOpp.Discovery_Chemistry__c != null)
                        {
                            str_OperatingUnit = 'Discovery Chemistry';
                        }
                        else if(objOpp.Safety_Assessment__c != null)
                        {
                            str_OperatingUnit = 'Safety Assessment';
                        }
                        else if(objOpp.Bioinformatics__c != null)
                        {
                            str_OperatingUnit = 'Computational and Data Sciences';
                        }
                    }      
                    if(objOpp.Biologics__c == true){
                        str_Division = 'Biologics';
                        if(objOpp.Biologics1__c!= null)
                        {
                            str_OperatingUnit = 'Biologics';
                        }
                    }    
                    if(objOpp.Development__c == true){
                        str_Division = 'Development';
                        if(objOpp.Chemical_Development__c != null)
                        {
                            
                            str_OperatingUnit = 'Chemical Development';
                        }
                        else if(objOpp.Formulation__c != null)
                        {
                            str_OperatingUnit = 'Formulation';
                        }
                        else if(objOpp.Stability__c != null)
                        {
                            str_OperatingUnit = 'Analytical Development';
                        }
                    }    
                    if(objOpp.Clinical_Development__c == true){
                        str_Division = 'Translational & Clinical Research (T&CR)';
                        
                        if(objOpp.Clinical_Development1__c != null)
                        {
                            str_OperatingUnit = 'Translational & Clinical Research (T&CR)';
                        }
                    }
                    
                }
                
                
                String closedMonth = calculateClosedMonth(objOpp.CloseDate);
                
                string str_Unique = objOpp.OwnerId+closedMonth+ string.valueof(objOpp.CloseDate.YEAR())+str_Division+str_OperatingUnit;
                //system.debug('str_Unique=====>>>>'+str_Unique);                
                if(map_Target.containskey(str_Unique))
                {
                    objOpp.Target__c = map_Target.get(str_Unique).Id;
                }
            }                      
        }
    }
    
    public static String calculateClosedMonth(Date closeDate) {
        if (closeDate == null) return 'None';
        
        Integer month = closeDate.month();
        switch on month {
            when 1 { return 'January'; }
            when 2 { return 'February'; }
            when 3 { return 'March'; }
            when 4 { return 'April'; }
            when 5 { return 'May'; }
            when 6 { return 'June'; }
            when 7 { return 'July'; }
            when 8 { return 'August'; }
            when 9 { return 'September'; }
            when 10 { return 'October'; }
            when 11 { return 'November'; }
            when 12 { return 'December'; }
            when else { return 'None'; }
        }
    }
}