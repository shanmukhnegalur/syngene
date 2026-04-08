/**
*  Purpose         :   This class is for Sales Pipeline Leakage Report
*
*  Create By       :   Aswanth Aravapalli
*
*  Created Date    :   30/05/2020
**/ 

public class SalesPipeLineLeakageUpdate {
    Public static void updateProgressing(map<Id,opportunity> Oldopportunitymap,List<opportunity> opplist){
        set<string> earlystageset=New set<string>();
        set<string> Potentialstageset=New set<string>();
        set<string> Confidentstageset=New set<string>();
        set<string> Verbalstageset=New set<string>();
        set<string> Winstageset=New set<string>();
        set<string> Loststageset=New set<string>();
        //set<string> earlystage1set=New set<string>();
        earlystageset.add('Budgetary');
        //
        earlystageset.add('Potential');
        earlystageset.add('Confident');
        earlystageset.add('Verbal');
        earlystageset.add('Contracting');
        //earlystageset.add('Win (100%)');
        //
        Potentialstageset.add('Confident');
        Potentialstageset.add('Verbal');
        Potentialstageset.add('Contracting');
        //Potentialstageset.add('Win (100%)');
        Confidentstageset.add('Verbal');
        Confidentstageset.add('Contracting');
        //Confidentstageset.add('Win (100%)');
        Verbalstageset.add('Contracting');
        //Verbalstageset.add('Win (100%)');
        Winstageset.add('Win');
        Loststageset.add('Lost');
        for(opportunity opp:opplist){
            try
            {
                if(Oldopportunitymap!=null && Oldopportunitymap.containskey(opp.id)){
                    if(Oldopportunitymap.get(opp.id).StageName=='Budgetary'){
                        string oppStageName=opp.StageName;
                        if(earlystageset.contains(oppStageName)){
                            opp.Progressing__c=true;
                        }
                    }
                    else if(Oldopportunitymap.get(opp.id).StageName=='Early Stage' ){ 
                        string oppStageName=opp.StageName;
                        if(earlystageset.contains(oppStageName)){
                            opp.Progressing__c=true;
                        }
                    }
                    else if(Oldopportunitymap.get(opp.id).StageName=='Potential' ){ 
                        string oppStageName=opp.StageName;
                        if(Potentialstageset.contains(oppStageName)){
                            opp.Progressing__c=true;
                        }                        
                    }
                    else if(Oldopportunitymap.get(opp.id).StageName=='Confident' ){ 
                        string oppStageName=opp.StageName;
                        if(Confidentstageset.contains(oppStageName)){
                            opp.Progressing__c=true;
                        }                        
                    }
                    else if(Oldopportunitymap.get(opp.id).StageName=='Verbal' ){ 
                        string oppStageName=opp.StageName;
                        if(Verbalstageset.contains(oppStageName)){
                            opp.Progressing__c=true;
                        }                        
                    }
                    if( opp.StageName=='Win'){ 
                        string oppStageName=opp.StageName;
                        if(Winstageset.contains(oppStageName)){
                            opp.Win__c=true;
                            opp.Progressing__c=false;
                        }
                        
                    }
                    if( opp.StageName=='Lost'){ 
                        string oppStageName=opp.StageName;
                        if(Loststageset.contains(oppStageName)){
                            opp.Win__c=false;
                            opp.Progressing__c=false;
                            opp.Lost__c=true;
                        }                        
                    }  
                }
            }
            catch(Exception e)
            {
                opp.addError(e.getMessage());
            }
        }
    }
}