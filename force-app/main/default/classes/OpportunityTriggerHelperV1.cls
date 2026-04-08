public class OpportunityTriggerHelperV1{
    
    public static boolean recordLockValidation = true;
    
    public static void opportunityRecordLock(List<Opportunity> lstOpp,map<id,Opportunity> oldMap){        
        if(OpportunityTriggerHelperV1.recordLockValidation){
            Set<String> ExcludedFields = new Set<String>(label.Exclude_Opportunity_Fields.split(','));
            Set<String> fieldNames = new Set<String>(getOpportunityFieldNames());
            string profile_id = userinfo.getProfileId().substring(0, 15);
            string User_id = userinfo.getUserId().substring(0,15);
            string RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sub Opportunity').getRecordTypeId();
            set<String> profileIds = new set<string>();
            set<String> userIds = new set<String>();
            Map<String, Schema.SObjectField> fieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();
            for(string str :label.Lock_Profile_to_Opportunity.split(','))
            {
                profileIds.add(String.valueOf(str).substring(0, 15));
            }
            for(string str :label.Lock_User_to_Opportunity.split(','))
            {
                userIds.add(String.valueOf(str).substring(0, 15));
            }
            system.debug('====Lock_User_to_Opportunity===='+label.Lock_User_to_Opportunity);
            for(Opportunity objOpp : lstOpp)
            {
                if(((oldMap.get(objOpp.id).StageName == 'Win' && objOpp.Opportuntiy_Edit_Access__c  == FALSE )|| oldMap.get(objOpp.id).StageName == 'Lost') && objOpp.recordTypeId != RecordTypeId)
                {
                    if(profileIds.contains(profile_id) || userIds.contains(User_id))
                    {
                    }
                    else if(!profileIds.contains(profile_id))
                    {   
                        for (String field : fieldNames) {
                            Schema.SObjectField myField = fieldMap.get(field);
                            if(myField.getDescribe().isPermissionable() && !myField.getDescribe().isCalculated() && !myField.getDescribe().isAutoNumber()){
                                if (!ExcludedFields.contains(field) && objOpp.get(field) != oldMap.get(objOpp.Id).get(field)) {
                                    objOpp.addError('No changes can be made in Opportunity if the Opportunity stage is Win (or) Lost. Please contact your System Administrator.');
                                }
                            }
                        }
                    }
                    else if(!userIds.contains(User_id))
                    {
                        for (String field : fieldNames) {
                            Schema.SObjectField myField = fieldMap.get(field);
                            if(myField.getDescribe().isPermissionable() && !myField.getDescribe().isCalculated() && !myField.getDescribe().isAutoNumber()){
                                if (!ExcludedFields.contains(field) && objOpp.get(field) != oldMap.get(objOpp.Id).get(field)) {
                                    objOpp.addError('No changes can be made in Opportunity if the Opportunity stage is Win (or) Lost. Please contact your System Administrator.');
                                }
                            }
                        }
                    }
                }
            }
        }
    } 
    public static void opportunityRecordLockRFXUser(List<Opportunity> lstOpp, Map<Id, Opportunity> oldMap) {
        Set<String> fieldNames = new Set<String>(getOpportunityFieldNames());
        Set<String> allowedFields = new Set<String>(label.Opportuntiy_Fields_Edit_Access.split(','));
        Set<String> ExcludedFields = new Set<String>(label.Exclude_Opportunity_Fields.split(','));
        Set<String> profileIds = new Set<String>(label.Lock_Oppty_after_7_days_Profiles.split(','));
        Set<String> userIds = new Set<String>(label.Lock_Oppty_after_7_days_Users.split(','));
        string profile_id = userinfo.getProfileId().substring(0, 15);
        string User_id = userinfo.getUserId().substring(0,15);
        String loggedInUserId = UserInfo.getUserId().substring(0, 15);
        String loggedInUserRole = System.UserInfo.getUserRoleId();
        
        Map<Id, String> rfxTeamMemberRoles = getRoleIdsByUserIds(getRfxTeamMemberUserIds(lstOpp));
        Map<String, Schema.SObjectField> fieldMap = Opportunity.getSObjectType().getDescribe().fields.getMap();
        
        for (Opportunity opp : lstOpp) {
            String rfxTeamMemberUserId = opp.RFX_Team_Member__c;
            String rfxTeamMemberRoleId = rfxTeamMemberRoles.get(rfxTeamMemberUserId);
            
            if (rfxTeamMemberRoleId == loggedInUserRole && opp.Opportuntiy_Edit_Access__c && oldMap.get(opp.id).StageName == opp.StageName) {
                for (String field : fieldNames) {
                    Schema.SObjectField myField = fieldMap.get(field);
                    if(myField.getDescribe().isPermissionable() && !myField.getDescribe().isCalculated() && !myField.getDescribe().isAutoNumber()){
                        if ((!allowedFields.contains(field) && !ExcludedFields.contains(field)) && opp.get(field) != oldMap.get(opp.Id).get(field)) {
                            opp.addError('No changes can be made in Opportunity if the Opportunity stage is Win');
                            break;
                        }
                    }
                }
            } else {
                if (rfxTeamMemberRoleId != loggedInUserRole &&
                    (opp.Opportuntiy_Edit_Access__c || !opp.Opportuntiy_Edit_Access__c) &&
                    (profileIds.contains(profile_id) || userIds.contains(User_id))) {
                        
                    } 
                else  if (rfxTeamMemberRoleId != loggedInUserRole && (opp.StageName == 'Win' && oldMap.get(opp.id).StageName == opp.StageName && opp.Stage_Prior_Value__c == 'Win') &&
                          (opp.Opportuntiy_Edit_Access__c || !opp.Opportuntiy_Edit_Access__c) &&!profileIds.contains(profile_id)) {
                              for (String field : fieldNames) {
                                  Schema.SObjectField myField = fieldMap.get(field);
                                  if(myField.getDescribe().isPermissionable() && !myField.getDescribe().isCalculated() && !myField.getDescribe().isAutoNumber()){
                                      if (!ExcludedFields.contains(field) && opp.get(field) != oldMap.get(opp.Id).get(field)) {  
                                          opp.addError('No changes can be made in Opportunity if the Opportunity stage is Win');
                                      }
                                  }
                              }
                              
                          } else if(rfxTeamMemberRoleId != loggedInUserRole && (opp.StageName == 'Win' && oldMap.get(opp.id).StageName == opp.StageName && opp.Stage_Prior_Value__c == 'Win') &&
                                    (opp.Opportuntiy_Edit_Access__c || !opp.Opportuntiy_Edit_Access__c) &&  !userIds.contains(User_id)) {
                                        for (String field : fieldNames) {
                                            Schema.SObjectField myField = fieldMap.get(field);
                                            if(myField.getDescribe().isPermissionable() && !myField.getDescribe().isCalculated() && !myField.getDescribe().isAutoNumber()){
                                                if (!ExcludedFields.contains(field) && opp.get(field) != oldMap.get(opp.Id).get(field)) {    
                                                    
                                                    opp.addError('No changes can be made in Opportunity if the Opportunity stage is Win');
                                                }
                                            }
                                        }
                                    }
                
            }
        }
    }

     public static List<String> getOpportunityFieldNames() {
        List<String> fieldNames = new List<String>();
        
        // Describe the Opportunity object
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType objType = gd.get('Opportunity');
        Schema.DescribeSObjectResult r = objType.getDescribe();
        
        // Retrieve all the fields and add their API names to the list if they are not formula or system fields
        Map<String, Schema.SObjectField> fields = r.fields.getMap();
        for (String fieldName : fields.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fields.get(fieldName).getDescribe();
           // && !fieldName.endsWithIgnoreCase('Date')
            if (!fieldDescribe.isCalculated() && !fieldDescribe.isAutoNumber()) {
                fieldNames.add(fieldDescribe.getName());
            }
        }
        
        return fieldNames;
    }
    public static String getRoleIdByUserId(String userId) {
        String roleId = null;
        List<User> userList = [SELECT UserRoleId FROM User WHERE Id = :userId LIMIT 1];
        if (!userList.isEmpty()) {  
            roleId = userList[0].UserRoleId;
        }
        return roleId;
    }
    public static Map<Id, String> getRoleIdsByUserIds(Set<Id> userIds) {
    Map<Id, String> userIdToRoleIdMap = new Map<Id, String>();
    for (User user : [SELECT Id, UserRoleId FROM User WHERE Id IN :userIds]) {
        userIdToRoleIdMap.put(user.Id, user.UserRoleId);
    }
    return userIdToRoleIdMap;
}

public static Set<Id> getRfxTeamMemberUserIds(List<Opportunity> lstOpp) {
    Set<Id> userIds = new Set<Id>();
    for (Opportunity opp : lstOpp) {
        if (opp.RFX_Team_Member__c != null) {
            userIds.add(opp.RFX_Team_Member__c);
        }
    }
    return userIds;
}
    public static void Validation(List<Opportunity> lstOpportunity)
    {
        Set<Id> setAccountIds = new set<Id>();
        map<Id,Account> map_Account = new map<Id,Account>();
        for(Opportunity opp : lstOpportunity)
        {
            if(opp.StageName == 'win' && opp.AccountId != null)
            {
                setAccountIds.add(opp.AccountId);
            }
        }
        if(setAccountIds.size() > 0)
        {
            
            for(account objAccount : [SELECT Id,Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, 
                                      BillingCountry, ShippingCity,ShippingCountry,ShippingPostalCode,ShippingState,ShippingStreet FROM Account where Id IN: setAccountIds])
            {
                map_Account.put(objAccount.Id,objAccount);
                
            }
        }
        
        if(map_Account.size() > 0)
        {
            for(opportunity objOpp : lstOpportunity)
            {
                if(map_Account.containsKey(objOpp.AccountId) && (map_Account.get(objOpp.AccountId).BillingCountry == null || 
                                                                 map_Account.get(objOpp.AccountId).BillingState == null ||
                                                                 map_Account.get(objOpp.AccountId).BillingCity == null 
                                                                 //map_Account.get(objOpp.AccountId).ShippingCity == null ||
                                                                // map_Account.get(objOpp.AccountId).ShippingCountry == null || 
                                                               //  map_Account.get(objOpp.AccountId).ShippingState == null
                                                                ))
                {
                    objOpp.addError('Please enter the Billing address details(City,State and Country) in the account '+map_Account.get(objOpp.AccountId).Name);
                }
            }
        }
    }
}