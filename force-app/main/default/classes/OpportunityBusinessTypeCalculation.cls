/**
*  Purpose         :   This class is to check validation of Business Type field of opportunity.
*
*  Create By       :   Sumit Sourav(PWC)
*
*  Created Date    :   17/08/2020
**/
public class OpportunityBusinessTypeCalculation {
    
    Public static void businesstypecalculation(List<Opportunity> newoptylist)
    {   
  /*      Try{
            Set<ID> accid=new Set<ID>();
            set<String> Businessunit=new Set<String>();
            Set<Id> accwithsapnull=new set<Id>();
            Set<Id> accwithsapnotnull=new set<Id>();
            Set<Id> accwithsapnotnullandwithwinopportunityLASTFY=new set<Id>();
            for(Opportunity o:newoptylist)
            {
                accid.add(o.accountid);
                Businessunit.add(o.Business_Unit__c);
            }
            system.debug('New Oppty'+newoptylist);
            List<Account> acc=[Select id,SAP_Account_Number__c from Account where ID IN :accid];
            for(Account a:acc)
            {
                if(a.SAP_Account_Number__c!=null)
                {
                    accwithsapnotnull.add(a.id);
                }
                if(a.SAP_Account_Number__c==null)
                {
                    accwithsapnull.add(a.id);
                }
                
            }
            system.debug('Acc with sap not null'+accwithsapnotnull);
            system.debug('Acc with sap null'+accwithsapnull);
            list<opportunity> PrevFYWonopptylist =[SELECT Id,closedate,accountid,Business_Unit__c,name,Stagename FROM Opportunity WHERE CloseDate =LAST_FISCAL_YEAR AND Accountid IN : accwithsapnotnull AND Business_Unit__c IN :Businessunit AND Stagename='Win (100%)'];
            system.debug('Last FY Opportunities'+PrevFYWonopptylist);
            if(PrevFYWonopptylist.size()>0)
            {
                for(Opportunity o:PrevFYWonopptylist)
                {
                    accwithsapnotnullandwithwinopportunityLASTFY.add(o.Accountid);
                }
            }
            system.debug('Account of win opty last FY-->'+accwithsapnotnullandwithwinopportunityLASTFY);
            system.debug('new opty account id-->'+newoptylist);
            for(Opportunity o1:newoptylist)
            {   
                string recordtypename = Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(o1.recordtypeid).getDeveloperName();
                if(accwithsapnotnull.contains(o1.accountid) && accwithsapnotnullandwithwinopportunityLASTFY.contains(o1.accountid))
                {   
                    for(Opportunity o2:PrevFYWonopptylist)
                    {   
                        if( o1.Business_Unit__c==o2.Business_Unit__c && o1.Business_Type__c=='New Account'&& o1.id!=o2.id && recordtypename!='Sub_Opportunity')
                        {   
                            o1.Business_Type__c.adderror('Opportunity '+o1.name +' should not have New Account under Business Type field since Opportunity '+o2.name+' had already won in last FY under '+o2.Business_Unit__c );
                        }
                        else if( o1.Business_Unit__c!=o2.Business_Unit__c && o1.Business_Type__c=='New Account'&& o1.id!=o2.id && recordtypename!='Sub_Opportunity' )
                        {   
                            o1.Business_Type__c='New Account';
                        }
                        
                    }
                    
                }
                else if(accwithsapnotnull.contains(o1.accountid) && (!accwithsapnotnullandwithwinopportunityLASTFY.contains(o1.accountid)) && recordtypename!='Sub_Opportunity')
                {   
                    o1.Business_Type__c='New Account';
                }
                else if(accwithsapnull.contains(o1.accountid) && recordtypename!='Sub_Opportunity')
                {   
                    o1.Business_Type__c='New Account';
                }
            }
        }Catch(Exception ex)
        {
            system.debug(ex);
        }
        */
    }
}