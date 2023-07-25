/*******************************************************************************************************
* @author Lev
* @date 2020
*
* @description Services for Affiliation object
*/
public with sharing class AffiliationService {
    /*******************************************************************************************************
    * @description  Check for, and prevent creation of, duplicate Affiliation records
    * @param        affiliations - list of Affiliation records
    */
    private static void handleDuplicates(List<npe5__Affiliation__c> affiliations) {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> orgIds = new Set<Id>();

        // Retrieve Contact and Organization IDs to query possible duplicates
        for (npe5__Affiliation__c affiliation : affiliations) {
            contactIds.add(affiliation.npe5__Contact__c);
            orgIds.add(affiliation.npe5__Organization__c);
        }

        // Retrieve any possible duplicates
        List<npe5__Affiliation__c> affiliationDuplicates = [
            SELECT Id, npe5__Contact__c, npe5__Organization__c
            FROM npe5__Affiliation__c
            WHERE npe5__Contact__c IN :contactIds
            AND npe5__Organization__c IN :orgIds
            AND npe5__StartDate__c != null 
            AND npe5__EndDate__c = null
        ];

        // Build keys to match against
        Set<String> matchingKeys = new Set<String>();
        for (npe5__Affiliation__c affiliation : affiliationDuplicates) {
            String matchingKey = affiliation.npe5__Organization__c + '-' + affiliation.npe5__Contact__c;
            matchingKeys.add(matchingKey);
        }

        // Add error for any duplicates found
        if (matchingKeys.size() > 0) {
            for (npe5__Affiliation__c affiliation : affiliations) {
                String matchingKey = affiliation.npe5__Organization__c + '-' + affiliation.npe5__Contact__c;
                if (matchingKeys.contains(matchingKey)) {
                    affiliation.addError('An Affiliation for Organization ' + affiliation.npe5__Organization__c + ' and Contact ' + affiliation.npe5__Contact__c + ' already exists.');
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description  Trigger gate for handling duplicates
    * param         affiliations - trigger new
    * param         oldAffiliationMap - trigger oldMap
    */
    public static void gateHandleDuplicates(List<npe5__Affiliation__c> affiliations, Map<Id, npe5__Affiliation__c> oldAffiliationMap) {
        List<npe5__Affiliation__c> affiliationsToHandle = new List<npe5__Affiliation__c>();

        // Only handle if affiliation has start date but no end date
        for (npe5__Affiliation__c affiliation : affiliations) {
            if (affiliation.npe5__StartDate__c != null && affiliation.npe5__EndDate__c == null) {
                // For insert, handle all active affiliations
                if (oldAffiliationMap == null) {
                    affiliationsToHandle.add(affiliation);
                }
                // For update, only handle active affiliations where Contact, Organization, Start Date, or End Date has changed
                else {
                    npe5__Affiliation__c oldAffiliation = oldAffiliationMap.get(affiliation.Id);
                    if (affiliation.npe5__StartDate__c != oldAffiliation.npe5__StartDate__c || affiliation.npe5__EndDate__c != oldAffiliation.npe5__EndDate__c) {
                        affiliationsToHandle.add(affiliation);
                    }
                } 
            }
        }
        // Send filtered affiliations to duplicate check
        if (affiliationsToHandle.size() > 0) {
            handleDuplicates(affiliationsToHandle);
        }
    }

    /*******************************************************************************************************
    * @description  Query for Account Summary records related to an Affiliation record
    * param         affiliation
    * return        List of Account Summary records related through matching Contact and Organization
    */
    @AuraEnabled
    public static List<Account_Summary__c> getRelatedAccountSummaries(npe5__Affiliation__c affiliation) {
        List<Account_Summary__c> acctSummaries = [
            SELECT Id, Name, Account_Type_display__c, Balance__c, Total_Credits__c
            FROM Account_Summary__c
            WHERE Member_Name__c = :affiliation.npe5__Contact__c
            AND Organization__c = :affiliation.npe5__Organization__c
        ];
        return acctSummaries;
    }
}