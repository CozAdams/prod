/**
* @author Nathan Ross
* 
* @date 2018-10
*
* @group ContactUserCreation
*
* @description For some leads, when we convert them, we want to on a delay 
* automatically create a community user for the associated contact.
*/
public interface IContactCommunityUserCreation {
    void beforeContactInsert(List<Contact> newContacts);
    void beforeContactUpdate(List<Contact> newContacts, Map<Id, Contact> oldContacts);
    void afterOpportunityInsert(List<Opportunity> newOpptys);
    void afterOpportunityUpdate(List<Opportunity> newOpptys, Map<Id, Opportunity> oldOpptys);
    Database.QueryLocator queryNeedsUserBeforeThreshold();
    void createUserForContacts(ILogger logger, List<Contact> contacts);
}