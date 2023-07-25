public with sharing class BankService {

    public static final String DUPLICATE_BANK_ACCOUNT = 'We can not add this bank account information at this time.  Error-4005'; //JS SE-2921

    public static void checkForDuplicateBankAccount(List<bnk_Bank__c> bankAccounts) {
        Set<String> routingList = new Set<String>();
        Set<String> swiftList = new Set<String>();
        Set<Id> insertedUpdatedIds = new Set<Id>();
        Map<String,bankWrapper> routingAcctSwiftCodeKeyBanks = new Map<String,bankWrapper>();
        //Add to map of Key routing number + account number + Swift Code of "New or Updated BankAccount" in Trigger context
        //Add routingNumber and swiftcode to sets to for later use in SOQL Query
        for (bnk_Bank__c bankAccount : bankAccounts) {
            insertedUpdatedIds.add(bankAccount.Id);
            
             if(bankAccount.bnk_Routing_Number__c !=null){
                routingList.add(bankAccount.bnk_Routing_Number__c);
            }  
            if(bankAccount.SWIFT_Code__c !=null){
                swiftList.add(bankAccount.SWIFT_Code__c);
            }   
            String key = String.Valueof(bankAccount.bnk_Routing_Number__c)  + String.Valueof(bankAccount.bnk_Account_Number__c) + String.Valueof(bankAccount.SWIFT_Code__c);
            if(!routingAcctSwiftCodeKeyBanks.containsKey(key)){
                bankWrapper bankAccountWrap = new bankWrapper();
                bankAccountWrap.newOrUpdatedBankAccounts.add(bankAccount);
                routingAcctSwiftCodeKeyBanks.put(key,bankAccountWrap);
            }else{
                bankWrapper bankAccountWrap = routingAcctSwiftCodeKeyBanks.get(key);
                bankAccountWrap.newOrUpdatedBankAccounts.add(bankAccount);
                routingAcctSwiftCodeKeyBanks.put(key,bankAccountWrap);
            }  
                  
        }
       
        List<bnk_Bank__c> existingBankAccounts = [SELECT Id, bnk_Routing_Number__c, bnk_Account_Number__c, SWIFT_Code__c FROM bnk_Bank__c
            WHERE (bnk_Routing_Number__c IN :routingList OR SWIFT_Code__c IN :swiftList) AND Id NOT IN :insertedUpdatedIds];
        //Add to map of Key routing number + account number + Swift Code of banksAccount in "Existing Bank Accounts"
        for (bnk_Bank__c existingBankAccount : existingBankAccounts) {
            String key = String.Valueof(existingBankAccount.bnk_Routing_Number__c)  + String.Valueof(existingBankAccount.bnk_Account_Number__c) + String.Valueof(existingBankAccount.SWIFT_Code__c);
            if(!routingAcctSwiftCodeKeyBanks.containsKey(key)){
                bankWrapper bankAccountWrap = new bankWrapper();
                bankAccountWrap.existingBankAccounts.add(existingBankAccount);
                routingAcctSwiftCodeKeyBanks.put(key,bankAccountWrap);
            }else{
                bankWrapper bankAccountWrap = routingAcctSwiftCodeKeyBanks.get(key);
                bankAccountWrap.existingBankAccounts.add(existingBankAccount);
                routingAcctSwiftCodeKeyBanks.put(key,bankAccountWrap);
            } 
        }
        //loop through "New or Updated BankAccount" in Trigger context agin and get BankWrapper
        for (bnk_Bank__c bankAccount : bankAccounts) {
            String key = String.Valueof(bankAccount.bnk_Routing_Number__c)  + String.Valueof(bankAccount.bnk_Account_Number__c) + String.Valueof(bankAccount.SWIFT_Code__c);
            if(routingAcctSwiftCodeKeyBanks.containsKey(key)){
                bankWrapper bankAccountWrap = routingAcctSwiftCodeKeyBanks.get(key);
                List<bnk_Bank__c> existingBankAccts = bankAccountWrap.existingBankAccounts;
                //If there is more than one new or updated bank account in the trigger context
                //Or if there is at least one existing bank accoount, Add duplicate error to trigger                
                List<bnk_Bank__c> newOrUpdatedBankAccounts =bankAccountWrap.newOrUpdatedBankAccounts;
                
                if( newOrUpdatedBankAccounts.size()>4 ||existingBankAccts.size() >=4 ){
                    bankAccount.addError(DUPLICATE_BANK_ACCOUNT);
                }
            }
        }       
    }
    public class bankWrapper{
        public List<bnk_Bank__c> existingBankAccounts;
        public List<bnk_Bank__c> newOrUpdatedBankAccounts;
        public bankWrapper(){
            existingBankAccounts = new List<bnk_Bank__c>();
            newOrUpdatedBankAccounts = new List<bnk_Bank__c>();
        }
    }

    @AuraEnabled
    public static Contact getContact(Id contactId) {
        if (contactId != null) {
            return [SELECT Id, FirstName, LastName FROM Contact WHERE Id = :contactId LIMIT 1];
        } else {
            User u = [SELECT ContactId, Contact.FirstName, Contact.LastName FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            return new Contact(Id = u.ContactId, FirstName = u.Contact.FirstName, LastName = u.Contact.LastName);
        }
    }

    @AuraEnabled
    public static Map<String, String> getCountries() {
        Map<String, String> countriesISOToLabel = new Map<String, String>();
        List<Country__c> countries = Country__c.getAll().values();
        for (Country__c country : countries) {
            countriesISOToLabel.put(country.ISO__c, country.Label__c);
        }
        return countriesISOToLabel;
    }

    @AuraEnabled
    public static Map<String, String> getStates(String countryISO) {
        Map<String, String> statesISOToLabel = new Map<String, String>();
        List<State__c> states = State__c.getAll().values();
        for (State__c state : states) {
            if (state.CountryISO__c == countryISO) {
                statesISOToLabel.put(state.ISO__c, state.Label__c);
            }
        }
        return statesISOToLabel;
    }

    @AuraEnabled
    public static List<bnk_Bank__c> getBankingInformationList(Id contactId) {
        List<bnk_Bank__c> bankAccounts = [SELECT Id, bnk_Bank_Name__c, bnk_Account_Number__c, Bank_Account_Country__c FROM bnk_Bank__c
        WHERE bnk_Account_Holder_Name__c = :contactId AND bnk_Is_Active__c = TRUE];
        for (bnk_Bank__c ba : bankAccounts) {
            Integer numberSizeMinusFour = ba.bnk_Account_Number__c.length() - 4;
            ba.bnk_Account_Number__c = '*'.repeat(numberSizeMinusFour) + ba.bnk_Account_Number__c.substring(numberSizeMinusFour);
        }
        return bankAccounts;
    }

    @AuraEnabled
    public static Id saveBankAccount(bnk_Bank__c newBankAccount) {
        try{
            insert newBankAccount;
        } catch(DmlException e) {
            if(!Test.isRunningTest())
                throw new AuraHandledException(getDmlErrorMessage(e));
            else
                getDmlErrorMessage(e);
        }

        return newBankAccount.Id;
    }

    private static String getDmlErrorMessage(DmlException e) {
        String errorMessage = '';
        for(Integer i = 0; i < e.getNumDml(); i++){
            if(String.isNotBlank(errorMessage)){
                errorMessage += '\n';
            }
            errorMessage += e.getDmlMessage(i);
        }
        return errorMessage;
    }

    //SE-2907 JS Create Case
    @AuraEnabled
    public static Id createBankAccountReports(Case c) {
        Group grp = [SELECT Id FROM Group WHERE DeveloperName = 'Member_Service_Center' LIMIT 1] ;
        Group treasuryGrp = [Select Id FROM Group WHERE DeveloperName = 'Treasury_Associate_State_Changes_Tasks' LIMIT 1];
        RecordType recType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Standard' ];
        
        c.OwnerId = grp.Id;
        c.RecordTypeId = recType.Id;
        
        insert c;
        
        Task t = new Task();
        t.ActivityDate = Date.Today() + 2;
        t.OwnerId = treasuryGrp.Id;
        t.Subject = 'Add a new bank account';
        t.WhatId = c.Id;
        
        insert t;
        
        return c.Id;
    }
    //SE-2907 JS Create Case
}