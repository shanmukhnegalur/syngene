/**
 *  Purpose         :   This class is tp create new contact role .
 *
 *  Create By       :   Sumit Kumar Sourav
 *
 *  Created Date    :   10/06/2020
**/ 
public class CreateNewContactRoles {

    // Per-transaction cache to avoid repeated SOQL on OpportunityContactRole
    public class Cache {
        public static Map<Id, Set<Id>> oppIdToContactIds; // OpportunityId -> Set of ContactIds that already have OCR
        public static Set<Id> queriedOppIds; // Track which Opps were already queried this transaction
    }

   Public Static void contactrolewhenopportunityinserts(List<Opportunity> opportunitylist)
    {
        List<OpportunityContactRole> OCR=new List<OpportunityContactRole>();
        for(Opportunity o:opportunitylist)
        {
            if(o.Contact__c!=Null)
            {
                system.debug('Creatubg OCR In lead');
                OCR.add(new OpportunityContactRole(ContactId=o.Contact__c,OpportunityId=o.Id,IsPrimary=true,Role='Decision Maker'));
            }
        }
        Try{
                if(OCR.size()>0)
                {
                   Insert OCR; 
                }
           }catch(Exception e) {
            System.debug(e);
            }
}
     Public Static void contactrolewhenopportunityupdates(List<Opportunity> newopportunitylist,Map<id,Opportunity> oldopportunitymap)
    {
        // Prepare lists and maps
        List<OpportunityContactRole> newContactRoleList = new List<OpportunityContactRole>();
        Map<Id,Id> opportunityWithOldContactForDelete = new Map<Id,Id>();      // oppId -> old contact (to delete old OCR)
        Map<Id,Id> opportunityNeedingOCRCheck = new Map<Id,Id>();              // oppId -> current contact (ensure OCR exists)

        // Build intent from new vs old values
        for(Opportunity opp : newopportunitylist) {
            Id newCon = opp.Contact__c;
            Id oldCon = (oldopportunitymap != null && oldopportunitymap.containsKey(opp.Id)) ? oldopportunitymap.get(opp.Id).Contact__c : null;

            // If contact changed from one value to another
            if(newCon != null && oldCon != null && newCon != oldCon) {
                opportunityWithOldContactForDelete.put(opp.Id, oldCon);
                // queue insert for new contact role (primary)
                newContactRoleList.add(new OpportunityContactRole(ContactId=newCon, OpportunityId=opp.Id, IsPrimary=true, Role='Decision Maker'));
                // also ensure we won't create duplicate for same contact later
                opportunityNeedingOCRCheck.put(opp.Id, newCon);
            }
            // If contact remained the same and is not null, ensure OCR exists (no duplicates)
            else if(newCon != null && oldCon != null && newCon == oldCon) {
                opportunityNeedingOCRCheck.put(opp.Id, newCon);
            }
            // If transitioned from null -> value, ensure OCR exists
            else if(newCon != null && oldCon == null) {
                opportunityNeedingOCRCheck.put(opp.Id, newCon);
            }
        }

        // Ensure OCR presence for all relevant opp/contact pairs in ONE pass with static cache
        checkcontactroleispresent(opportunityNeedingOCRCheck);

        try{
            if(!opportunityWithOldContactForDelete.isEmpty()) {
                deletecontactrolewhenopportunityupdates(opportunityWithOldContactForDelete); 
            }
            if(!newContactRoleList.isEmpty()) {
               insert newContactRoleList; 
            }
        } catch(Exception e) {
            System.debug(e);
        }
     }
    Public Static void deletecontactrolewhenopportunityupdates(Map<id,Id> Opportunitywithcontact)
    {
        List<OpportunityContactRole> existingocr=new list<OpportunityContactRole>();
        existingocr=[select id,opportunityid,contactid from OpportunityContactRole where opportunityid IN :Opportunitywithcontact.keyset()];
    	List<OpportunityContactRole> deleteocr=new list<OpportunityContactRole>();
        for(Id opp:Opportunitywithcontact.keyset())
        {
            for(OpportunityContactRole o:existingocr)
            {
                if(opp==o.Opportunityid)
                {
					if(o.contactid==Opportunitywithcontact.get(opp))
                    {
                        deleteocr.add(o);
                    }                    
                } 
            }
        }
        Try{
                if(deleteocr.size()>0)
                {
                   Delete deleteocr; 
                }
           }catch(Exception e) {
            System.debug(e);
            }
     }
    // Commented this method on 26/06/2024 because it is creating Duplicate Contact Roles while doing Bulk upload
    /*Public Static void checkcontactroleispresent2(Map<Id,Id> Opportunitywithcontact)
    {
          System.debug('Opportunitywithcontact ==>'+Opportunitywithcontact);
        Map<ID,Id> MapofOpptytocontactwithocrpresent=new Map<ID,ID>();
        List<OpportunityContactRole> existingocr=new list<OpportunityContactRole>();
        List<OpportunityContactRole> createocr=new list<OpportunityContactRole>();
        existingocr=[select id,opportunityid,contactid from OpportunityContactRole where opportunityid IN :Opportunitywithcontact.keyset()];
    	for(Id i:Opportunitywithcontact.keyset())
        {
            System.debug('i ==>'+i);
            for(OpportunityContactRole ocr:existingocr)
            {
                System.debug('ocr ==>'+ocr);
                 System.debug('i ==>'+i);
                if(i==ocr.opportunityid && ocr.contactid==Opportunitywithcontact.get(i))
                {
                     System.debug('enetring==>MapofOpptytocontactwithocrpresent ');
                    MapofOpptytocontactwithocrpresent.put(i,ocr.contactid);//ocr present for contact and opty
                }
            }
        }
        if(MapofOpptytocontactwithocrpresent.size()>0)
        {
             System.debug('MapofOpptytocontactwithocrpresent ==>'+MapofOpptytocontactwithocrpresent);
            system.debug('==='+MapofOpptytocontactwithocrpresent.size());
            for(Id i:Opportunitywithcontact.keyset())
            {
               
                 System.debug('i2 ==>'+i);
                for(Id c:MapofOpptytocontactwithocrpresent.keyset())
                {
                     System.debug('c2 ==>'+c);
                    if(i!=c)
                    {
                        System.debug('enetring==>MapofOpptytocontactwithocrpresent2 ');
                        createocr.add(new OpportunityContactRole(ContactId=Opportunitywithcontact.get(i),OpportunityId=i,IsPrimary=true,Role='Decision Maker'));
                    }
                }
            }
        }
        else if(MapofOpptytocontactwithocrpresent.size()==0)
        {
            system.debug('==='+MapofOpptytocontactwithocrpresent.size());
            for(Id i:Opportunitywithcontact.keyset())
            {
                createocr.add(new OpportunityContactRole(ContactId=Opportunitywithcontact.get(i),OpportunityId=i,IsPrimary=true,Role='Decision Maker'));
            }
        }
        Try{
            If(createocr.size()>0)
            {
                system.debug('==='+createocr.size());
                insert createocr;
            }
        }catch(Exception e) {
            System.debug(e);
            }
     }*/
    public static void checkcontactroleispresent(Map<Id, Id> opportunityWithContact) {
        if(opportunityWithContact == null || opportunityWithContact.isEmpty()) {
            return;
        }
        System.debug('Opportunitywithcontact ==>' + opportunityWithContact);

        // Initialize cache if needed
        if(Cache.oppIdToContactIds == null) {
            Cache.oppIdToContactIds = new Map<Id, Set<Id>>();
        }
        if(Cache.queriedOppIds == null) {
            Cache.queriedOppIds = new Set<Id>();
        }

        // Determine which opps still need querying (not yet in cache)
        Set<Id> oppsToQuery = new Set<Id>();
        for(Id oppId : opportunityWithContact.keySet()){
            if(!Cache.oppIdToContactIds.containsKey(oppId) && !Cache.queriedOppIds.contains(oppId)){
                oppsToQuery.add(oppId);
            }
        }

        // Single SOQL for all not-yet-cached opportunities
        if(!oppsToQuery.isEmpty()){
            for(OpportunityContactRole ocr : [
                SELECT Id, OpportunityId, ContactId
                FROM OpportunityContactRole
                WHERE OpportunityId IN :oppsToQuery
            ]){
                if(!Cache.oppIdToContactIds.containsKey(ocr.OpportunityId)){
                    Cache.oppIdToContactIds.put(ocr.OpportunityId, new Set<Id>());
                }
                Cache.oppIdToContactIds.get(ocr.OpportunityId).add(ocr.ContactId);
            }
            // Mark these opps as queried in this transaction
            Cache.queriedOppIds.addAll(oppsToQuery);
        }

        // Build list to create only those missing OCRs
        List<OpportunityContactRole> createOCR = new List<OpportunityContactRole>();
        for (Id oppId : opportunityWithContact.keySet()) {
            Id targetContactId = opportunityWithContact.get(oppId);
            Set<Id> cachedContacts = Cache.oppIdToContactIds.containsKey(oppId) ? Cache.oppIdToContactIds.get(oppId) : new Set<Id>();
            Boolean alreadyExists = cachedContacts.contains(targetContactId);

            if(!alreadyExists){
                createOCR.add(new OpportunityContactRole(
                    ContactId = targetContactId,
                    OpportunityId = oppId,
                    IsPrimary = true,
                    Role = 'Decision Maker'
                ));
                // Optimistically add to cache to prevent duplicate creation within same txn
                if(!Cache.oppIdToContactIds.containsKey(oppId)){
                    Cache.oppIdToContactIds.put(oppId, new Set<Id>());
                }
                Cache.oppIdToContactIds.get(oppId).add(targetContactId);
            }
        }

        if (!createOCR.isEmpty()) {
            try {
                insert createOCR;
                System.debug('Inserted OCRs: ' + createOCR.size());
            } catch (Exception e) {
                System.debug('Error inserting OCRs: ' + e.getMessage());
            }
        }
    }
}