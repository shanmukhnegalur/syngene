public class LinkedInHelper {
    public static Boolean isTriggerFired = false;
    
    public static void processOpportunities(List<Opportunity> opportunities) {
        
        if (!opportunities.isEmpty()) {
            Map<Id, Opportunity> contactToOpportunityMap = new Map<Id, Opportunity>();
            
            for (Opportunity opp : opportunities) {
                if (opp.Contact__c != null) { // Use Contact__c field
                    contactToOpportunityMap.put(opp.Contact__c, opp); // Map each Opportunity to Contact__c
                    if (!LinkedInContactWrapper.processedOpportunityIds.contains(opp.Id)) {
                        LinkedInContactWrapper.processedOpportunityIds.add(opp.Id); 
                    }
                }
            }
            
            // Query Contacts based on the keys in contactToOpportunityMap
            List<Contact> relatedContacts = [
                SELECT Id, FirstName, LastName, Email, Title, Account.Name, MailingCountryCode, Integrated_with_LinkedIn__c
                FROM Contact
                WHERE Id IN :contactToOpportunityMap.keySet()
            ];
            
            // Process both Contacts and Opportunities
            LinkedInConversionEventService.processContactsForConversion(relatedContacts, contactToOpportunityMap);
        }
    }
    
    public static void processContacts(List<Contact> contacts) {
        if (!contacts.isEmpty()) {
            system.debug('Entering processContacts');
            LinkedInConversionEventService.processContactsForConversion(contacts, null);
        }
    }
    public static String getConversionRuleByStage(String stageName) {
        // Check if stageName is not blank
        if (String.isNotBlank(stageName)) {
            try {
                // Query the Custom Metadata Type for the corresponding conversion rule
                LinkedIn_CAPI_Conversion_Rules__mdt conversionRule = [
                    SELECT ConversionRuleId__c 
                    FROM LinkedIn_CAPI_Conversion_Rules__mdt
                    WHERE Opportunity_Stage_Name__c = :stageName
                    LIMIT 1
                ];
                 system.debug('stageName==>'+stageName) ;
               system.debug('optyconversionRule==>'+conversionRule) ;
                // If a conversion rule is found for the stage name, return it
                if (conversionRule != null) {
                    return conversionRule.ConversionRuleId__c;
                }
            } catch (Exception ex) {
                System.debug('Error fetching conversion rule for stage: ' + ex.getMessage());
            }
        }
        
        // Fallback: fetch the default rule (where Opportunity_Stage_Name__c is empty)
        try {
            LinkedIn_CAPI_Conversion_Rules__mdt contactConversionRule = [
                SELECT ConversionRuleId__c 
                FROM LinkedIn_CAPI_Conversion_Rules__mdt
                WHERE Opportunity_Stage_Name__c = ''
                LIMIT 1
            ];
            system.debug('stageName==>'+stageName) ;
             system.debug('contactConversionRule==>'+contactConversionRule) ;
            if (contactConversionRule != null) {
                return contactConversionRule.ConversionRuleId__c;
            }
        } catch (Exception ex) {
            System.debug('Error fetching default conversion rule: ' + ex.getMessage());
        }
        
        // Return null or a default rule ID if no match is found
        return null;
    }
    
}