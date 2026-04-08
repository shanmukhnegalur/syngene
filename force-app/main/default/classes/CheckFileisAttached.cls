/**
*  Purpose         :   This class is to check whether a File is mandatory on opportunity .
*
*  Create By       :   Sumit Kumar Sourav
*
*  Created Date    :   17/07/2020
**/
public class CheckFileisAttached {
    
    Public static void attachmentcheck(List<Opportunity> New_Opportunity)
    {
        Try
        {
            Set<Id> Oppid=new Set<Id>();
            List<contentdocumentlink> file=new List<contentdocumentlink>();
            for(Opportunity opp:New_Opportunity) {
                Oppid.add(opp.Id);
            }
            If(Oppid.size()>0) {
                file =[select contentdocumentid,linkedentityid from contentdocumentlink where linkedentityid IN :Oppid]; 
                
            }            
            set<Id> OpportunitywithDocument=new set<Id>();
            for(contentdocumentlink cd:file) {
                OpportunitywithDocument.add(cd.linkedentityid);
            }            
            for(Opportunity o:New_Opportunity)  {  
                if(o.recordtypeid != null)
                {
                    string recordtypename = Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(o.recordtypeid).getDeveloperName();
                    if(o.Do_you_have_approvals_per_pricing_policy__c=='Yes'&& recordtypename!='Sub_Opportunity' && !( OpportunitywithDocument.contains(o.id))  )
                    {
                        o.adderror('Please upload the pricing approval document in the “Files” section under “Overview” of opportunity.');
                    }
                }
            } 
        }Catch(Exception e)
        {
            New_Opportunity[0].addError(e.getMessage());
        }
    }
}