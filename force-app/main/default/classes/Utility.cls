/**
*  Purpose         :   Utility class to serve as a class to store methods that are commonly used as well as provide static variables to bypass triggers/Apex processes when necessary.
*
*  Create By       :   Rajeev Jain(PWC)
*
*  Created Date    :   27/12/2018
*
*  Revision Logs   :   V_1.0 - Created
**/
public class Utility {
    
    //==========================Static Properties and various Trigger Bypass Flags =======================================================
    //Flag to bypass any trigger on runtime, it will mainly help in Bulk data updates, After Trigger Operations etc.
    public static Boolean BYPASS_ALL_TRIGGERS = false;
    
    //Get System Admin Contact for Sending Template Based emails and use as fake Target Object Id
    public static Contact defaultContact{
        get {
            //Process Logic only once when DefaultContact first time called
            if(defaultContact == null){
                
                    //Find out Default Admin Contact fro the org
                    List<Contact> ct = [select Id, Name, Email from Contact where Name = :Constant.SF_ADMIN AND Email != null LIMIT 1];
                    
                    if(ct.size() > 0)
                        return ct[0];
                    else{
                        
                        //If Default Admin Contact not found then, insert one dummy contact and retunr it.
                        //Ensure this dummy contact got deleted, once your email based puprose get solved
                        defaultContact = new Contact(LastName = Constant.SF_ADMIN_LAST_NAME,firstName=Constant.SF_ADMIN_FIRST_NAME, Email = Constant.SF_ADMIN_EMAIL, ByPassValidation__c = true,
                                                     MailingCity=Constant.SF_ADMIN_MAILING_CITY,MailingCountry = Constant.SF_ADMIN_MAILING_COUNTRY);
                        insert defaultContact;
                    
                        return defaultContact;
                    }
            } 
            
            //Each time return a default contact
            return defaultContact;
        }
        set;
    }
    
    //Populate Service Unites(Portfolio, Business Unit, Sub Business Unit) Mapping Data 
    public static Map<String, String> serviceUnitesMap{
        get{
            if(serviceUnitesMap == null){
                
                serviceUnitesMap = new Map<String, String>();
                
                for(Business_Unit__mdt buData : [SELECT Id, DeveloperName, MasterLabel, Label, Portfolio__r.Label, Active__c 
                                         FROM Business_Unit__mdt
                                        where Active__c = true AND Portfolio__r.Active__c = true]
                ){
                    
                    serviceUnitesMap.put(buData.Label, buData.Portfolio__r.Label);   
                }
                
                for(Sub_Business_Unit__mdt subBuData : [SELECT Id, DeveloperName, MasterLabel, Label, Business_Unit__r.Label, Active__c, Business_Unit__r.Portfolio__r.Label
                                                 FROM Sub_Business_Unit__mdt
                                                where Active__c = true AND Business_Unit__r.Active__c = true AND Business_Unit__r.Portfolio__r.Active__c = true]
                ){
                    
                    serviceUnitesMap.put(subBuData.Label, subBuData.Business_Unit__r.Label);   
                }
            } 
            return serviceUnitesMap;
        }
        set;
    }
    
    //Populate State Country Metadata - Help in Address Validation on Any Object
  public static Map<String,Set<String>> countryStateMap{
        
        get{
            
            if(countryStateMap == null){
                
                countryStateMap = new Map<String,Set<String>>();
                
                //Quqery on State data order by Country
                for(SAP_Country__mdt country : [SELECT DeveloperName,MasterLabel, (SELECT DeveloperName,MasterLabel FROM SAP_States__r) FROM SAP_Country__mdt]){
                    
                    Set<String> stateSet = new Set<String>();
                    
                    for(SAP_State__mdt st : country.SAP_States__r){
                        
                        stateSet.add(st.MasterLabel);
                        
                    }
                    countryStateMap.put(country.MasterLabel,stateSet);    
                }
            }
            return countryStateMap;
        }
        set;
    }
    
    //Populate State Country Metadata - Help in Address Validation on Any Object
  public static Map<String,Set<String>> countryStateMapGoogleLabel{
        
        get{
            
            if(countryStateMapGoogleLabel == null){
                
                countryStateMapGoogleLabel = new Map<String,Set<String>>();
                
                //Quqery on State data order by Country
                for(SAP_Country__mdt country : [SELECT DeveloperName,MasterLabel,Google_Label__c, (SELECT DeveloperName,MasterLabel,Google_Label__c FROM SAP_States__r) FROM SAP_Country__mdt]){
                    
                    Set<String> stateSet = new Set<String>();
                    
                    for(SAP_State__mdt st : country.SAP_States__r){
                        
                        stateSet.add(st.Google_Label__c);
                        
                    }
                    if(!(countryStateMapGoogleLabel.containsKey(country.Google_Label__c))){
                        countryStateMapGoogleLabel.put(country.Google_Label__c,stateSet);  
                    }
                }
            }
            
            return countryStateMapGoogleLabel;
        }
        set;
    }
    
    //========================================= Class Methods ============================================================================
     /**
     *    @description    :   Method to send Apex/API email based on HTML or Plain Text Body to multiple To, CC & BCC Address(Normal Email Sending Method)
     *
     *    @Revisions      :   27/12/2018 - Added by - Rajeev Jain(PWC) - Syngene CRM implementation Phase 1
     * 
     *    @args           :   toAddress/ccAddress/bccAddress - Can contain direct email addresses or Contact/Lead/User Id
     *                        emailOptOutPolicy - Obey GDPR Guidelines, Set emailOptOutPolicy = 'Filter', if using Object id in Address option and don't want to sent the notification to opt out Contact/Lead.
     * 
     *    @return         :   void
     * 
    **/
    public static Messaging.SingleEmailMessage createEmail(List<string> toAddresses, List<String> ccAddresses, List<String> bccAddresses,
                                                           String subject, String body, String htmlBody,
                                                           List<Messaging.EmailFileAttachment> attachments, Boolean saveAsActivity){
    
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // email address of the salesforce email service
        mail.setToAddresses(toAddresses);
        mail.setCcAddresses(ccAddresses);
        mail.setBccAddresses(bccAddresses);
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        mail.setHtmlBody(htmlBody);
                                                                       
        //Send Attachment through email, if Exist
        if (attachments != null && attachments.size() > 0)
            mail.setFileAttachments(attachments);
        
        //If This flag is true, Email would be stored in Activity History
        mail.setSaveAsActivity(saveAsActivity);
                                                               
        return mail;
    }
    
     /**
     *    @description    :   Method to send emails based on Target Object Id, And Pre Defined Template. 
     *                          This not count against of Daily Limit of Emails(5000) if Target Object Id mentioned as User.
     *                        Few Conditions : Make saveActivity = false, if target object id is user.
     *                                         If What Id is mentioned then User Id can't use in Target Object Id.
     *                                         Target Object Id and Template Id use vise versa, can't use solely. 
     *
     *    @Revisions      :   27/12/2018 - Added by - Rajeev Jain(PWC) - Syngene CRM implementation Phase 1
     * 
     *    @args           :   toAddress/ccAddress/bccAddress - Can contain direct email addresses or Contact/Lead/User Id
     * 
     *    @return         :   void
     * 
    **/
    public static Messaging.SingleEmailMessage createEmail(List<String> toAddresses, List<String> ccAddresses, List<String> bccAddresses,
                                                           Id whatId, Id targetObjectId, Id templateId, 
                                                           Boolean saveAsActivity,
                                                           List<Messaging.EmailFileAttachment> attachments){
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(templateId);
        mail.setToAddresses(toAddresses);
        mail.setCcAddresses(ccAddresses);
        mail.setBccAddresses(bccAddresses);
        mail.setWhatId(whatId);
        mail.setTargetObjectId(targetObjectId);
        
        //Send Attachment through email, if Exist
        if (attachments != null && attachments.size() > 0)
            mail.setFileAttachments(attachments);
        
        /*if(String.isNotBlank(emailOptOutPolicy))
            mail.optoutpolicy = emailOptOutPolicy;*/
                                                               
        //If This flag is true, Email would be stored in Activity History
        mail.setSaveAsActivity(saveAsActivity);
        return mail;
    }
    
    //Method to Send Email - In Single transaction maximum 100 email can be sent.
    public static void sendEmail(List<Messaging.SingleEmailMessage> mails) {
            Messaging.sendEmail(mails);
        
    }
    
    //Prepare Attachment rady through Blob passed it
    public static Messaging.EmailFileAttachment createEmailAttachment(string filename, blob body) {
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(filename);
        efa.setBody(body);
        return efa;
    }
    
    //method to send emails
    public static void sendEmail(String toAddress, String subject, String body) {
    
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       // email address of the salesforce email service
       String[] toAddresses = new String[] {toAddress};
       mail.setToAddresses(toAddresses);
       mail.setSubject(subject);
       mail.setPlainTextBody(body);
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    /**
     *    @description    :   Method to populate multi-select picklist
     *
     *    @Revisions      :   27/12/2018 - Added by - Madhurima(PWC) - Syngene CRM implementation Phase 1
     * 
     *    @args           :   List of SObjects, Map of SObjects
     * 
     *    @return         :   void
     * 
    **/
    public static void saveMultiselectPicklist(List<Sobject> records, Map<Id, Sobject> oldRecordsMap){
    
        String bypassBu = Label.ByPass_BU_Logic;
        if(bypassBu == 'false'){
            List<SObject> objectList = new List<SObject>();
            for(Sobject record : records){
                
                Id sObjectId = (ID)record.get('Id');
                String sObjName;
                if(sObjectId != null){
                    sObjName = sObjectId.getSObjectType().getDescribe().getName();
                    system.debug('sObjName'+sObjName);
                }
                
                if(oldRecordsMap == null || (oldRecordsMap != null && 
                   (record.get('Discovery__c') != oldRecordsMap.get(sObjectId).get('Discovery__c') ||
                    record.get('Development__c') != oldRecordsMap.get(sObjectId).get('Development__c') || 
                    record.get('Biologics__c') != oldRecordsMap.get(sObjectId).get('Biologics__c') ||
                    record.get('Biologics1__c') != oldRecordsMap.get(sObjectId).get('Biologics1__c') ||
                    record.get('Clinical_Development__c') != oldRecordsMap.get(sObjectId).get('Clinical_Development__c') //||
                   // record.get('Is_this_SynVent__c') != oldRecordsMap.get(sObjectId).get('Is_this_SynVent__c')
                   )))
                {
                    String portfolioString = '';
                    if(record.get('Discovery__c') == true){
                        portfolioString = portfolioString + 'Discovery' + ';';
                    }
                    if(record.get('Development__c') == true){
                        portfolioString = portfolioString + 'Development' + ';';
                    }
                    
                   if(sObjName !='Account')
                    {
                        if(record.get('Biologics__c') == true){
                            portfolioString = portfolioString + 'Biologics' + ';';
                        }
                    }
                    else{
                        if(record.get('Biologics1__c') == true){
                           portfolioString = portfolioString + 'Biologics' + ';';
                        }
                    }
                     
				/* if(sObjName =='Opportunity')//Opportunity
                 {
                     system.debug('isOppty');
                     if(record.get('Is_this_SynVent__c') == 'Yes'){
                         system.debug('Is_this_SynVent__c');
                          portfolioString = portfolioString + 'SynVent' + ';';
                     }
                 }*/
                    if(record.get('Clinical_Development__c') == true){
                        portfolioString = portfolioString + 'Translational & Clinical Research (T&CR)' + ';';
                    }

                    //It will not work on Syngene Historical Opportunity Data, until unless this flag is not marked as false.
                    if(record.get('Is_Historical_Data__c') != true)
                        record.put('Portfolio__c', portfolioString.removeEnd(';'));
                }
                
                if(oldRecordsMap == null || (oldRecordsMap != null && 
                   (record.get('Discovery_Biology__c') != oldRecordsMap.get(sObjectId).get('Discovery_Biology__c') ||
                    record.get('Discovery_Chemistry__c') != oldRecordsMap.get(sObjectId).get('Discovery_Chemistry__c') || 
                    record.get('Bioinformatics__c') != oldRecordsMap.get(sObjectId).get('Bioinformatics__c') ||
                    record.get('Safety_Assessment__c') != oldRecordsMap.get(sObjectId).get('Safety_Assessment__c') ||
                    record.get('Chemical_Development__c') != oldRecordsMap.get(sObjectId).get('Chemical_Development__c') ||
                    record.get('Formulation__c') != oldRecordsMap.get(sObjectId).get('Formulation__c') ||
                    record.get('Stability__c') != oldRecordsMap.get(sObjectId).get('Stability__c') ||
                    record.get('Biologics1__c') != oldRecordsMap.get(sObjectId).get('Biologics__c') ||
                    record.get('Biologics__c') != oldRecordsMap.get(sObjectId).get('Biologics__c') ||
                    record.get('Clinical_Development1__c') != oldRecordsMap.get(sObjectId).get('Clinical_Development1__c') ||
                     record.get('SynVent_Dropdown__c') != oldRecordsMap.get(sObjectId).get('SynVent_Dropdown__c') 
                    //||
                    //record.get('Synvent__c') != oldRecordsMap.get(sObjectId).get('Synvent__c') ||
                    //record.get('CMC__c') != oldRecordsMap.get(sObjectId).get('CMC__c') ||
                    //record.get('Manufacturing_API__c') != oldRecordsMap.get(sObjectId).get('Manufacturing_API__c')                    
                   )))
                {
                    String buString = '';
                    if(record.get('Discovery_Biology__c') != null && record.get('Discovery_Biology__c') != null){
                        buString = buString + 'Discovery Biology' + ';';
                    }
                    if(record.get('Discovery_Chemistry__c') != null && record.get('Discovery_Chemistry__c') != null){
                        buString = buString + 'Discovery Chemistry' + ';';
                    }
                    if(record.get('Bioinformatics__c') != null && record.get('Bioinformatics__c') != null){
                        buString = buString + 'Computational and Data Sciences' + ';';
                    }
                    if(record.get('Safety_Assessment__c') != null && record.get('Safety_Assessment__c') != null){
                        buString = buString + 'Safety Assessment' + ';';
                    }
                    if(record.get('Chemical_Development__c') != null && record.get('Chemical_Development__c') != null){
                        buString = buString + 'Chemical Development' + ';';
                    }
                    if(record.get('Formulation__c') != null && record.get('Formulation__c') != null){
                        buString = buString + 'Formulation' + ';';
                    }
                    if(record.get('Stability__c') != null && record.get('Stability__c') != null){
                        buString = buString + 'Stability' + ';';
                    }
                    if(sObjName =='Opportunity')
                 {
                     if(record.get('SynVent_Dropdown__c')  != null){
                        buString = buString + 'SynVent' + ';';
                     }
                    
                 }
                     if(sObjName !='Account')
                    {
                    if(record.get('Biologics1__c') != null && record.get('Biologics1__c') != null){
                        System.debug('Is it entering here');
                        buString = buString + 'Biologics' + ';';
                    }
                    }
                    else{
                          if(record.get('Biologics__c') != null && record.get('Biologics__c') != null){
                        System.debug('Is it entering here');
                        buString = buString + 'Biologics' + ';';
                    }
                    }
                    
                    if(record.get('Clinical_Development1__c') != null && record.get('Clinical_Development1__c') != null){
                        buString = buString + 'Translational & Clinical Research (T&CR)' + ';';
                    }
                    /*if(record.get('Synvent__c') != null && record.get('Synvent__c') != null){
                        buString = buString + 'Synvent' + ';';
                    }
                     if(record.get('CMC__c') != null && record.get('CMC__c') != null){
                        buString = buString + 'CMC' + ';';
                    }
                     if(record.get('Manufacturing_API__c') != null && record.get('Manufacturing_API__c') != null){
                        buString = buString + 'Manufacturing-API' + ';';
                    } */                   
                    //It will not work on Syngene Historical Opportunity Data, until unless this flag is not marked as false.
                    if(record.get('Is_Historical_Data__c') != true)
                        record.put('Business_Unit__c', buString.removeEnd(';'));
                }
            }
        }
    }
    
    /**
     *    @description    :   Method to validate the Service Unit Data
     *
     *    @Revisions      :   27/12/2018 - Added by - Rajeev Jain(PWC) - Syngene CRM implementation Phase 1
     * 
     *    @args           :   List of opportunities
     * 
     *    @return         :   void
     * 
    **/
    public static void validateMultiselectServiceInterests(List<Sobject> records, Map<Id, Sobject> oldRecordsMap ){
        
        //Loop over new records
        for(Sobject record : records){
            
            Id sObjectId = (ID)record.get('Id');
           
            
            if(
                oldRecordsMap == null || 
               (
                   oldRecordsMap != null && 
                (
                    record.get('Portfolio__c') != oldRecordsMap.get(sObjectId).get('Portfolio__c') || 
                    record.get('Business_Unit__c') != oldRecordsMap.get(sObjectId).get('Business_Unit__c') || 
                    record.get('Sub_Business_Unit__c') != oldRecordsMap.get(sObjectId).get('Sub_Business_Unit__c')
                )
               )   
            ){
                
                Utility.validateServiceUnitData(record);                
            }
        }
    }
    
    /**
     *    @description    :   Method to process logic to check valid Service unit data
     *
     *    @Revisions      :   27/12/2018 - Added by - Rajeev Jain(PWC) - Syngene CRM implementation Phase 1
     * 
     *    @args           :   Trigger Context Opportunity
     * 
     *    @return         :   void
     * 
    **/
    public static void validateServiceUnitData(Sobject triggerObj){
        
        String portfolio = String.valueOf(triggerObj.get('Portfolio__c'));
        String BU = String.valueOf(triggerObj.get('Business_Unit__c'));
        String subBU = String.valueOf(triggerObj.get('Sub_Business_Unit__c'));
        
        //All three units are blank then don't process logic
        if(String.isNotBlank(portfolio) || String.isNotBlank(BU) || String.isNotBlank(subBU)){
            
            //Set to hold Portfolio values
            Set<String> setPortfolio = new Set<String>();
            Set<String> setBu = new Set<String>();
            
            //Flag to Check if correct values populated for Portfolio, if BU is not blank
            Boolean isBuValid = true;
            Boolean isSubBuValid = true;
            
            if(String.isNotBlank(portfolio)){
                for(String str :portfolio.split(';'))
                    setPortfolio.add(str);    
            }
            if(String.isNotBlank(BU)){
                for(String str :BU.split(';'))
                    setBu.add(str);
            }
            
            if(String.isBlank(BU))
                isBuValid = true;
            else{
                if(setPortfolio.size() == 0){
                    
                    triggerObj.addError(Constant.PORTFOLIO_BLANK_ERROR);  
                    return;
                }     
                
                for(String str :setBu){
                    
                    if(Utility.serviceUnitesMap.containsKey(str) && !setPortfolio.contains(Utility.serviceUnitesMap.get(str))){
                        isBuValid = false;
                        break;
                    }
                }
            }
            
            //If Bu Not found relavent then display error message 
            if(!isBuValid){
                
                triggerObj.addError(Constant.BU_VALIDATION_ERROR);
                return;
            }
            
            if(String.isBlank(subBU))
                isSubBuValid = true;
            else{
                
                if(setBu.size() == 0){
                    
                    triggerObj.addError(Constant.BU_BLANK_ERROR);   
                    return;
                }
                
                for(String str :subBU.split(';')){
                    
                    //setBu.add(str);
                    if(Utility.serviceUnitesMap.containsKey(str) && !setBu.contains(Utility.serviceUnitesMap.get(str))){
                        isSubBuValid = false;
                        break;
                    }
                }
            }
            
            //If Bu Not found relavent then display error message 
            if(!isSubBuValid)
                triggerObj.addError(Constant.SUB_BU_VALIDATION_ERROR);  
            
        }
    } 
    
    /**
     *    @description    :   Method to get Field Set's fields on run time based on field set name and object name passed to it.
     *
     *    @Revisions      :   13/02/2019 - Added by - Rajeev Jain(PWC) - Syngene CRM implementation Phase 1
     * 
     *    @args           :   Field Set Name, Object Name of which field set is required.
     * 
     *    @return         :   void
     * 
    **/
    public static List<Schema.FieldSetMember> getFieldDetails(String fieldSetName, String objectName){
        
        List<String> fieldDetails = new List<String>();
        
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        
        Map <String, Schema.FieldSet> fieldMap = schemaMap.get(objectName).getDescribe().fieldSets.getMap();
        return fieldMap.get(fieldSetName).getFields();
    }
    
    /**
     *    @description    :   Method to return field names based on field set memebr passed to it.
     *
     *    @Revisions      :   13/02/2019 - Added by - Rajeev Jain(PWC) - Syngene CRM implementation Phase 1
     * 
     *    @args           :   Field Set Name and Object Name
     * 
     *    @return         :   void
     * 
    **/
    public static List<String> getFieldLabels(String fieldSetName, String objectName){
        
        List<String> fieldDetails = new List<String>();
        
        for(Schema.FieldSetMember fieldSetMemberObj : Utility.getFieldDetails(fieldSetName,objectName)){
            fieldDetails.add(fieldSetMemberObj.getLabel());
            System.debug('Check Field Set API name ::: ' + fieldSetMemberObj.getFieldPath());
        }
        return fieldDetails;
    }
    
    /*Madhurima Start*/
    public static Map<String ,Map<String, String>> getPicklistAPIValues(String fieldSetName, String objectName){
        Map<String, Map<String, String>> picklistAPINameWithValueAPIs = new Map<String, Map<String,String>>();        
              
        for(Schema.FieldSetMember fieldSetMemberObj : Utility.getFieldDetails(fieldSetName,objectName)){ 
            Map<String, String> picklistAPIValues = getPickListValuesIntoMap(objectName, fieldSetMemberObj.getFieldPath());
            picklistAPINameWithValueAPIs.put(fieldSetMemberObj.getFieldPath(), picklistAPIValues);
        }
        return picklistAPINameWithValueAPIs;
    }
    
    public static Map<String, String> getPickListValuesIntoMap(String objectApiName, String fieldApiName){
        Map<String, String> pickListNameAndValueMap= new Map<String, String>();
        
        // Get the describe for the object
        DescribeSObjectResult objResult = orgSchemaMap.get(objectApiName).getDescribe();
        // Get the field dynamically
         DescribeFieldResult fieldResult = objResult.fields.getMap().get(fieldApiName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListNameAndValueMap.put(pickListVal.getLabel(), pickListVal.getValue());
        }     
        return pickListNameAndValueMap;
    }
    
    /*Madhurima End*/
    
    //Get System Admin Contact for Sending Template Based emails and use as fake Target Object Id
    public static Map <String, Schema.SObjectType> orgSchemaMap{
        get {
            //Process Logic only once when DefaultContact first time called
            if(orgSchemaMap == null){
                
                orgSchemaMap = Schema.getGlobalDescribe();
            }
            return orgSchemaMap;
        }
        set;
    }
    
    /**
     *    @description    :   Method to get BU Roles Dynmically
     *
     *    @Revisions      :   13/02/2019 - Added by - Rajeev Jain(PWC) - Syngene CRM implementation Phase 1
     * 
     *    @args           :   FieldSet Details
     * 
     *    @return         :   void
     * 
    **/
    private static List<String> p_Roles;
    
    public static List<String> getBURoles(List<Schema.FieldSetMember> buFields, Sobject obj){
        
        if(p_Roles == null){
            
            p_Roles = new List<String>();
        
            for(Schema.FieldSetMember buField : buFields){
                        
                if(obj.get(buField.getFieldPath()) != null){ 
                    p_Roles.add(buField.getLabel() + Constant.BU_HEAD_ROLE_SUFFIX);      
                }
            }
        }
        
        return p_Roles;
    }
    
    /**
     *    @description    :   Method to get BU Roles Role Map Dynamically At Run Time
     *
     *    @Revisions      :   13/02/2019 - Added by - Rajeev Jain(PWC) - Syngene CRM implementation Phase 1
     * 
     *    @args           :   FieldSet Details
     * 
     *    @return         :   void
     * 
    **/
    public static Map<String, List<User>> getRolesWithUsers(Set<String> roles){
        
        //Map to Hold the Assigned User corrosponding to Each Role
        Map<String, List<User>> mapRoleWithUsers = new Map<String, List<User>>();
        
        if(roles.size() > 0 ){
            for(User user : [select Id, UserRole.Name, Email from User where UserRole.Name IN :roles]){
                
                if(mapRoleWithUsers.containsKey(user.UserRole.Name))
                    mapRoleWithUsers.get(user.UserRole.Name).add(user);
                else
                    mapRoleWithUsers.put(user.UserRole.Name, new List<User>{user});
            }
        }
        return mapRoleWithUsers;
     }
    
    //Common Logic to Prepare Mail List for the all types of Reminders
    /**
     *    @description    :   Method to Process template based emails, mainly used to send various Business Unit based notifications.
     *
     *    @Revisions      :   13/02/2019 - Added by - Rajeev Jain(PWC) - Syngene CRM implementation Phase 1
     * 
     *    @args           :   FieldSet Details
     * 
     *    @return         :   void
     * 
    **/
    public static void processMailToSentList(List<Sobject> objList, 
                                            List<Messaging.SingleEmailMessage> mailsToSend,
                                            Map<String, List<User>> mapRoleWithUsers,
                                            String templateId,
                                            List<Schema.FieldSetMember> buFields,
                                            String objectName){
        
        //Loop over each Sobject and Prepare Notifcation Email and add it to the list
        for(Sobject obj : objList){
            
            //Prepare To Addresss
            List<String> toAddresses = new List<String>();
            
            //Set to hold unique Recipients
            Set<String> toAddressUnique = new Set<String>();
            
            toAddressUnique.add(String.valueOf(obj.get('OwnerId')));
            
            //Loop over each Selected Business Unit, Create Role and get the assigned user corrospondibng to it
            for(Schema.FieldSetMember buField : buFields){
                    
                if(obj.get(buField.getFieldPath()) != null){
                    
                    String role = buField.getLabel() + Constant.BU_HEAD_ROLE_SUFFIX; 
                    
                    if(mapRoleWithUsers.containsKey(role)){
                        
                        for(User user : mapRoleWithUsers.get(role)){
                            toAddressUnique.add(user.Id);  
                        }
                    }
                }
            }
            
            //Convert Set to List
            toAddresses.addAll(toAddressUnique);
            
            if(toAddresses.size() > 0){
                
                //Using Template Based Logic and in context to use opportunity as What Id, we need to provide Contact Id as Target Object Id
                //Logic to bypass Actual Target Object Id and send the email using Email Template
                //Query System Admin Contact for the Fake Target Object Id
                Id whatId = objectName == 'Opportunity' ? (Id)(obj.get('Id')) : null;
                
                Messaging.SingleEmailMessage mail = Utility.createEmail(toAddresses, null, null, whatId , Utility.defaultContact.Id, templateId, true, null);
                mailsToSend.add(mail);
                
            }
        }
                                                
        //If any email to send then send it.
        if(mailsToSend.size() > 0){
                
             //Prepare Save point to Rollback 
             //It will help us to Populate Template Data with Mege fields for time being and will solve the purpose to don't use Target object Id
             Savepoint sp = Database.setSavepoint();
                
             Utility.sendEmail(mailsToSend);
                
             //Rollback mail sending
             Database.rollback(sp);
                
             //Now Prepare Back mail list and send the simple mail without target object id
             List<Messaging.SingleEmailMessage> msgListToBeSend = new List<Messaging.SingleEmailMessage>();
    
             for (Messaging.SingleEmailMessage email : mailsToSend) 
                    
                 msgListToBeSend.add(Utility.createEmail(email.getToAddresses(), email.getCcAddresses(), email.getBccAddresses(), 
                                                            email.getSubject(), email.getPlainTextBody(), email.getHTMLBody(), null, false));
                
              //Send mail with Prepared Content
              Utility.sendEmail(msgListToBeSend);
        }
    }
    /**
     *    @description    :   Method to convert mapping data in encoded data
     *
     *    @Revisions      :   02/04/2019 - Added by - Rajeev Jain(PWC) - Syngene CRM implementation Phase 1
     * 
     *    @args           :   Field Data
     * 
     *    @return         :   void
     * 
    **/
    public static String validateMappingData(String data){
        
        //Check if Data Is Null
        if(String.isBlank(data))
            data = '';
        if(data.contains('&'))
            data = data.replaceAll('\\&', '&amp;');
        return data;
    }
}