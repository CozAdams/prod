public with sharing class BillerDirectSHO {
    
    @AuraEnabled(cacheable=true)
    public static String getFieldValues(String AccountSummaryId, String email, String amount, String taxYear){
        System.debug('in callout method');
        Account_Summary__c associatedAccount;
        BillerSHOwrapperClass wrapperValues = new BillerSHOwrapperClass();
        System.debug('Account Id =' + AccountSummaryId);
        associatedAccount = [Select Id, Member_Pin__c, Member_Name__r.Name, Member_Name__r.Id, Account_Number__c, Account_Type__c, Member_Name__r.Age__c FROM Account_Summary__c Where Id =: AccountSummaryId][0];

        String stringToHash = associatedAccount.Account_Number__c + amount + associatedAccount.Member_Name__r.Name + associatedAccount.Member_Pin__c + email + associatedAccount.Member_Name__r.Id + associatedAccount.Id + taxYear + 'true' + 'Pe$1on'; //JS SE-2804 Added Tax Year
        //String hashValue = SHA512(stringToHash);
        wrapperValues.Account = associatedAccount;
        wrapperValues.hashValue = stringToHash;
        System.debug('hash value --- ' + stringToHash);
        System.debug('hash value --- ' + stringToHash);
        Blob blobString = Blob.valueOf(stringToHash);
        Blob hashValue = Crypto.generateDigest('SHA-512', blobString);
        System.debug('hash value ' + hashValue);
        wrapperValues.hashValue = EncodingUtil.convertToHex(hashValue);
        System.debug(wrapperValues.hashValue);
        return JSON.serialize(wrapperValues);
        


    }
        
}