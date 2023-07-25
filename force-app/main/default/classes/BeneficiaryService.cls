/**
 * Controller class for BeneficiaryList Lightning Component.
 *
 * @author Bluewolf
*/
public with sharing class BeneficiaryService {
    public static final String retrievalError = 'Unable to retrieve beneficiaries:';
    public static final String saveError = 'Unable to save beneficiary:';
    @testVisible
    private static final String UPDATE_TYPE_NEW = 'New Record';
    @testVisible
    private static final String UPDATE_TYPE_EXISTING = 'Update of Existing Record';
    @testVisible
    private static final String CASE_STATUS_CLOSED = 'Closed';

    @AuraEnabled
    public static Account_Summary__c getAccountSummaryById(Id summaryId){
        Account_Summary__c summary = [SELECT Name, Member_Name__c, Account_Number__c, Account_Type__c
        FROM Account_Summary__c
        WHERE Id = :summaryId
        LIMIT 1];
        return summary;
    }

    @AuraEnabled
    public static List<BeneficiaryListWrapper> getBeneficiariesBySummaryId(Id summaryId){
        List<BeneficiaryListWrapper> wrapperList = new List<BeneficiaryListWrapper>();

        if(String.isNotEmpty(summaryId)){
            List<Beneficiary__c> results = [SELECT Id, Beneficiary_Percentage__c, Beneficiary_Type__c, Relationship2__r.Id,
                    Relationship2__r.npe4__Type__c, Contact__r.Id, Contact__r.FirstName,
                    Contact__r.LastName, Contact__r.Email,Contact__r.Phone, Contact__r.Birthdate,
                    Contact__r.Social_Security_Number__c, Contact__r.MailingStreet, Contact__r.OtherStreet,
                    Contact__r.MailingCity, Contact__r.OtherCity, Contact__r.MailingState,Contact__r.OtherState,
                    Contact__r.MailingPostalCode, Contact__r.OtherPostalCode, Contact__r.MailingCountry,
                    Contact__r.OtherCountry
            FROM Beneficiary__c WHERE Account_Summary__c=:summaryId];

            for(Beneficiary__c b : results) {
                BeneficiaryListWrapper wrapper = new BeneficiaryListWrapper();
                wrapper.id = b.Id;
                wrapper.contact = b.Contact__r;
                wrapper.relationship = b.Relationship2__r;
                wrapper.beneficiary = new Beneficiary__c(Id=b.Id, Beneficiary_Type__c=b.Beneficiary_Type__c,
                        Beneficiary_Percentage__c= b.Beneficiary_Percentage__c);
                wrapperList.add(wrapper);
            }
        }
        return wrapperList;
    }

    @AuraEnabled
    public static Map<String,String> getPicklistOptions(String objectName, String fieldName) {
        Map<String,String> types = new Map<String,String>();
        Schema.DescribeSObjectResult objDescribe = ((SObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        for(Schema.PicklistEntry pe : fieldMap.get(fieldName).getDescribe().getPicklistValues()) {
            types.put(pe.getLabel(),pe.getValue());
        }
        return types;
    }

    @AuraEnabled
    public static void saveBeneficiaries(String accountSummaryId, String beneficiaries) {
        List<BeneficiaryListWrapper> wrappers =
                (List<BeneficiaryListWrapper>)JSON.deserialize(beneficiaries, List<BeneficiaryListWrapper>.class);
        List<Id> beneficiaryIds = new List<Id>();
        Account_Summary__c accountSummary = [SELECT Member_Name__c, Member_Name__r.Name
        FROM Account_Summary__c
        WHERE Id = :accountSummaryId
        LIMIT 1];
        Map<Id, SObject> oldValuesMap = new Map<Id, SObject>();
        Map<String, List<SObject>> sObjTypeMap = new Map<String, List<SObject>>();
        sObjTypeMap.put('Contact', new List<SObject>());
        sObjTypeMap.put('Beneficiary__c', new List<SObject>());
        sObjTypeMap.put('npe4__Relationship__c', new List<SObject>());
        List<BeneficiaryListWrapper> wrappersToInsert = new List<BeneficiaryListWrapper>();


        for(BeneficiaryListWrapper w : wrappers){
            // fix the added scale decimal from deserialization
            w.beneficiary.Beneficiary_Percentage__c = Integer.valueOf(w.beneficiary.Beneficiary_Percentage__c);

            if(w.beneficiary.Id != null){
                beneficiaryIds.add(w.beneficiary.Id);
                sObjTypeMap.get('Contact').add(w.contact);
                sObjTypeMap.get('Beneficiary__c').add(w.beneficiary);
                sObjTypeMap.get('npe4__Relationship__c').add(w.relationship);
            }else{
                wrappersToInsert.add(w);
            }
        }

        //build the map of existing data
        List<Beneficiary__c> results = new List<Beneficiary__c>([SELECT Beneficiary_Percentage__c, Beneficiary_Type__c,
                Relationship2__r.Id,Relationship2__r.npe4__Type__c, Relationship2__r.npe4__RelatedContact__c,
                Relationship2__r.npe4__Contact__c,Contact__r.Id, Contact__r.FirstName,Contact__r.LastName, Contact__r.Email,
                Contact__r.Phone,Contact__r.Birthdate, Contact__r.Social_Security_Number__c, Contact__r.MailingStreet,
                Contact__r.OtherStreet, Contact__r.MailingCity, Contact__r.OtherCity, Contact__r.MailingState,
                Contact__r.OtherState,Contact__r.MailingPostalCode, Contact__r.OtherPostalCode, Contact__r.MailingCountry,
                Contact__r.OtherCountry
        FROM Beneficiary__c WHERE Id = :beneficiaryIds]);

        Map<Id, SObject> oldSObjectMap = new Map<Id, SObject>();
        for(Beneficiary__c b : results) {
            oldSObjectMap.put(b.Contact__r.Id, b.Contact__r);
            oldSObjectMap.put(b.Relationship2__r.Id, b.Relationship2__r);
            oldSObjectMap.put(b.Id, new Beneficiary__c(Id=b.Id, Beneficiary_Type__c=b.Beneficiary_Type__c,
                    Beneficiary_Percentage__c=b.Beneficiary_Percentage__c));
        }


        Savepoint sp = Database.setSavepoint();
        try {
            //insert the new records, add to the sObjTypeMap
            if(!wrappersToInsert.isEmpty()) {
                Map<String, List<SObject>> insertedObjMap = createBeneficiaries(accountSummary.Member_Name__c, wrappersToInsert);
                for (String sObjType : insertedObjMap.keySet()) {
                    sObjTypeMap.get(sObjType).addAll(insertedObjMap.get(sObjType));
                }
            }

            //create the case
            Id caseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Standard').getRecordTypeId();
            Case mainCase = new Case(RecordTypeId=caseRecordType, Status='Closed');
            insert mainCase;

            //Create the update sobject list and the community user records
            List<Community_User_Update__c> userUpdates = new List<Community_User_Update__c>();
            List<SObject> sObjectsToUpdate = new List<SObject>();  //used to store filtered out updates

            for(String objType : sObjTypeMap.keySet()) {
                List<SObject> sObjList = sObjTypeMap.get(objType);


                for (SObject sobj : sObjList) {
                    SObject sObjToUpdate = null;
                    Id currentCaseId = mainCase.Id;

                    //Check to see if a secondary case needs to be created
                    if(sobj instanceOf Contact) {

                        if (!oldSObjectMap.containsKey(sObj.Id)) {
                            Case c = new Case(RecordTypeId = caseRecordType);
                            insert c;
                            currentCaseId = c.Id;
                        } else if (((Contact) oldSObjectMap.get(sObj.Id)).Social_Security_Number__c != ((Contact) sobj).Social_Security_Number__c ) {
                            Case c = new Case(RecordTypeId = caseRecordType);
                            insert c;
                            currentCaseId = c.Id;
                        }
                    }


                    //get the populated fields and their previous values and create community user update records
                    if (sobj != null) {
                        Map<String, Object> fieldsToValue = sObj.getPopulatedFieldsAsMap();
                        for (String fieldName : fieldsToValue.keySet()) {
                            Object value = fieldsToValue.get(fieldName);

                            Community_User_Update__c cuUpdate = new Community_User_Update__c();
                            cuUpdate.Object__c = objType;
                            cuUpdate.Case__c = currentCaseId;
                            cuUpdate.Existing_Record_ID__c = sObj.Id;
                            cuUpdate.Field__c = fieldName;
                            cuUpdate.New_Value__c = value instanceOf Decimal ?
                                    String.valueOf(((Decimal) value).setScale(4)) :
                                    String.valueOf(value);


                            if (oldSObjectMap.containsKey(sObj.Id)) {
                                Object oldValue = oldSObjectMap.get(sObj.Id).get(fieldName);
                                cuUpdate.Old_Value__c = oldValue instanceOf Decimal ?
                                        String.valueOf(((Decimal) oldValue).setScale(4)) :
                                        String.valueOf(oldValue);
                                cuUpdate.Type__c = UPDATE_TYPE_EXISTING;

                                if (cuUpdate.Old_Value__c != cuUpdate.New_Value__c) {
                                    if (sObjToUpdate == null) {
                                        sObjToUpdate = (SObject) Type.forName(objType).newInstance();
                                        sObjToUpdate.put('Id', sobj.Id);
                                    }
                                    sObjToUpdate.put(fieldName, fieldsToValue.get(fieldName));

                                    //create the master case if it wasn't set to an alternative
                                    if (currentCaseId == null) {
                                        if (mainCase.Id == null) {
                                            insert mainCase;
                                        }
                                        currentCaseId = mainCase.Id;
                                        cuUpdate.Case__c = currentCaseId;
                                    }

                                    userUpdates.add(cuUpdate);
                                }
                            } else {
                                //create the master case if it wasn't set to an alternative
                                if (currentCaseId == null) {
                                    if (mainCase.Id == null) {
                                        insert mainCase;
                                    }
                                    currentCaseId = mainCase.Id;
                                    cuUpdate.Case__c = currentCaseId;
                                }

                                cuUpdate.Type__c = UPDATE_TYPE_NEW;
                                userUpdates.add(cuUpdate);
                            }
                        }
                    }

                    if(sObjToUpdate != null) {
                        sObjectsToUpdate.add(sObjToUpdate);
                    }
                }
            }

            Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.DuplicateRuleHeader.allowSave = true;
            dmlOptions.optAllOrNone = false;
            Database.update(sObjectsToUpdate, dmlOptions);
            Database.insert(userUpdates, true);

        }catch(BeneficiaryException e){
            Database.rollback(sp);
            AuraHandledException ae = new AuraHandledException(e.getMessage());
            ae.setMessage(e.getMessage());
            throw ae;
//        }catch(Exception e){
//            Database.rollback(sp);
//            AuraHandledException ae = new AuraHandledException(saveError+e.getMessage());
//            ae.setMessage(saveError+e.getMessage());
//            throw ae;
        }
    }

    @TestVisible
    private static Map<String, List<SObject>> createBeneficiaries(Id primaryContactId, List<BeneficiaryListWrapper> beneficiaries){
        Map<String, List<SObject>> returnMap = new Map<String, List<SObject>>();

        List<Contact> contactsToInsert = new List<Contact>();
        List<npe4__Relationship__c> relationshipsToInsert = new List<npe4__Relationship__c>();
        List<Beneficiary__c> beneficiariesToInsert = new List<Beneficiary__c>();

        for(BeneficiaryListWrapper b : beneficiaries){
            contactsToInsert.add(b.contact);
            relationshipsToInsert.add(b.relationship);
            beneficiariesToInsert.add(b.beneficiary);
        }

        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.DuplicateRuleHeader.allowSave = true;
        dmlOptions.optAllOrNone = false;
        List<Database.SaveResult> srList = Database.insert(contactsToInsert, dmlOptions);

        for(Integer i=0; i<srList.size(); i++){
            Database.SaveResult sr = srList[i];
            if(sr.isSuccess()){
                relationshipsToInsert[i].npe4__RelatedContact__c = sr.getId();
                relationshipsToInsert[i].npe4__Contact__c = primaryContactId;
                beneficiariesToInsert[i].Contact__c = sr.getId();
            }else{
                String msg = 'Error creating contact '+contactsToInsert[i].FirstName+' '+contactsToInsert[i].LastName+': ';
                for(Database.Error e : sr.getErrors()){
                    msg += e.getMessage();
                }
                throw new BeneficiaryException(msg);
            }
        }

        srList = new BeneficiaryTrampoline().saveRelationships(relationshipsToInsert);
        for(Integer i=0; i<srList.size(); i++){
            Database.SaveResult sr = srList[i];
            if(sr.isSuccess()){
                beneficiariesToInsert[i].Relationship2__c = sr.getId();
            }else{
                String msg = 'Error creating relationship for '+
                        contactsToInsert[i].FirstName+
                        ' '+contactsToInsert[i].LastName+
                        '. Please contact support.';
                throw new BeneficiaryException(msg);
            }
        }

        srList = new BeneficiaryTrampoline().saveBeneficiaries(beneficiariesToInsert);
        for(Integer i=0; i<srList.size(); i++){
            Database.SaveResult sr = srList[i];
            if(!sr.isSuccess()){
                System.debug(sr.getErrors());
                String msg = 'Error creating beneficiary for '+
                        contactsToInsert[i].FirstName+' '+
                        contactsToInsert[i].LastName+
                        '. Please contact support.';
                throw new BeneficiaryException(msg);
            }
        }


        returnMap.put('Contact', contactsToInsert);
        returnMap.put('npe4__Relationship__c', relationshipsToInsert);
        returnMap.put('Beneficiary__c',beneficiariesToInsert);
        return returnMap;
    }

    without sharing class BeneficiaryTrampoline {
        List<Database.SaveResult> saveRelationships(List<npe4__Relationship__c> relationships) {
            return Database.insert(relationships, false);
        }
        List<Database.SaveResult> saveBeneficiaries(List<Beneficiary__c> beneficiaries) {
            return Database.insert(beneficiaries, false);
        }
    }

    public class BeneficiaryException extends Exception {}
}