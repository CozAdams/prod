public with sharing class BankTriggerHandler {
    private List<bnk_Bank__c> newBankAccounts;
    private List<bnk_Bank__c> oldBankAccounts;
    private Map<Id, bnk_Bank__c> newBankAccountsMap;
    private Map<Id, bnk_Bank__c> oldBankAccountsMap;

    public BankTriggerHandler(List<bnk_Bank__c> newBankAccounts, List<bnk_Bank__c> oldBankAccounts, Map<Id, bnk_Bank__c> newBankAccountsMap, Map<Id, bnk_Bank__c> oldBankAccountsMap) {
        this.newBankAccounts = newBankAccounts;
        this.oldBankAccounts = oldBankAccounts;
        this.newBankAccountsMap = newBankAccountsMap;
        this.oldBankAccountsMap = oldBankAccountsMap;
    }

    public void onBeforeInsert() {
        BankService.checkForDuplicateBankAccount(newBankAccounts);
    }

    public void onBeforeUpdate() {
        BankService.checkForDuplicateBankAccount(newBankAccounts);
    }
}