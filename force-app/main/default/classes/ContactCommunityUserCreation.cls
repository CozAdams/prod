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
global with sharing class ContactCommunityUserCreation implements IContactCommunityUserCreation {

    public static final String CREATED_USER_PROFILE_NAME='PFCC Customer CPL - Member';
    public static final String STAGE_ENROLLMENT_COMPLETE='Enrollment Complete';
    public static final String MESSAGE_NO_EMAIL_ON_CONTACT='This action would create a community user for the associated contact, however community users must have an e-mail and this contact does not ahve an email';
    public static final Integer USER_CREATION_DELAY_HOURS=1;
    public class NoEmailException extends Exception {}

    public void beforeContactInsert(List<Contact> newContacts) {
        markNeedsNewUser(filterNeedsNewUser(newContacts, null));
    }

    public void beforeContactUpdate(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        markNeedsNewUser(filterNeedsNewUser(newContacts, oldContacts));
    }

    public void afterOpportunityInsert(List<Opportunity> newOpptys) {
        stampNeedsNewUserOnContact(filterNewlyEnrolledWithContact(newOpptys, null));
    }

    public void afterOpportunityUpdate(List<Opportunity> newOpptys, Map<Id, Opportunity> oldOpptys) {
        stampNeedsNewUserOnContact(filterNewlyEnrolledWithContact(newOpptys, oldOpptys));
    }

    /**
     * @description finds contacts that first needed a user more than an hour and a half ago
     */
    public Database.QueryLocator queryNeedsUserBeforeThreshold() {
        final Datetime beginning = Datetime.newInstance(2020, 2, 11, 1, 0, 0);
        final Datetime threshold = System.now().addHours(-1 * USER_CREATION_DELAY_HOURS);
        final String query = String.format(
                'SELECT Email, FirstName, LastName FROM Contact WHERE User_Needed_Datetime__c > {0} AND User_Needed_Datetime__c < {1} AND Email != NULL',
                new List<String>{ datetimeToSoqlString(beginning), datetimeToSoqlString(threshold) });
        return Database.getQueryLocator(query);
    }

    @InvocableMethod(Label='Create Users' Description='Creates Users For Contacts')
    global static List<Id> createUserForContacts(List<Contact> contacts) {
        ILogger iLogger = new LoggerFactoryDefault().createLogger(
                LoggerStrategy.EMAIL,
                LogLevel.ERROR,
                'Contact User Creation',
                'Creates users for eligibile community contacts');
        new ContactCommunityUserCreation().createUserForContacts(iLogger, contacts);
        List<User> users = [SELECT Id FROM User WHERE ContactId IN :Pluck.ids(contacts)];
        return new List<Id>(Pluck.ids(users));
    }

    public void createUserForContacts(ILogger logger, List<Contact> contacts) {
        List<User> usersForContacts = buildUsersForContacts(contacts);
        Map<Id, Contact> contactsIdMap = new Map<Id, Contact>(contacts);
        List<Database.SaveResult> saveResults = new InsertTrampoline().insertUsersForContacts(usersForContacts);
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Integer i=0; i<saveResults.size(); i++) {
            Database.SaveResult result = saveResults[i];
            if (!result.isSuccess()) {
                logger.log(
                    result.getErrors()[0].getMessage(),
                    ContactCommunityUserCreation.class,
                    contactsIdMap.get(usersForContacts[i].ContactId));
            } else {
                contactsToUpdate.add(new Contact(
                    Id=usersForContacts[i].ContactId,
                    User_Needed_Datetime__c=null
                ));
            }
        }
        logger.handleErrorLogging(
            Database.update(contactsToUpdate, false),
            contactsToUpdate,
            '',
            ContactCommunityUserCreation.class);
    }

    public List<User> buildUsersForContacts(List<Contact> contacts) {
        List<User> usersForContacts = new List<User>();
        Profile userProfile = [ SELECT Id FROM Profile WHERE Name =: CREATED_USER_PROFILE_NAME ];
        // fail gracefully if the contact was manuallly created.
        List<Contact> hasNoUser =
            filterContactHasNoUser(contacts);
        for (Contact contactSobj : hasNoUser) {
            // we will not have formula values without an extra query in all contexts
            if (contactSobj.Email == null) {
                throw new NoEmailException(MESSAGE_NO_EMAIL_ON_CONTACT);
            }
            String uniqueStr =
                    EncodingUtil.convertToHex(Crypto.generateDigest('MD5',
                        Blob.valueOf(contactSobj.Email)));
            usersForContacts.add(new User(
                Alias = uniqueStr.left(8),
                CommunityNickname = (contactSobj.FirstName + ' ' + contactSobj.LastName).left(40),
                ContactId = contactSobj.Id,
                Email = contactSobj.email,
                EmailEncodingKey = 'ISO-8859-1',
                FirstName = contactSobj.FirstName,
                LastName = contactSobj.LastName,
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = userProfile.Id,
                TimeZoneSidKey = 'America/New_York',
                Username = contactSobj.Email,
                SpringCMEos__SpringCM_User__c = True
            ));
        }
        return usersForContacts;
    }

    String datetimeToSoqlString(Datetime dt) {
        return dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    List<Contact> filterNeedsNewUser(List<Contact> newContacts, Map<Id, Contact> oldContactsMap) {
        List<Contact> results = new List<Contact>();
        for (Contact newContact: newContacts) {
            if (newContact.User_Needed_Datetime__c == null && newContact.Member_Portal_User__c &&
                (oldContactsMap == null || ! oldContactsMap.get(newContact.Id).Member_Portal_User__c)) {
                results.add(newContact);
            }
        }
        return filterContactHasNoUser(results);
    }

    List<Contact> filterContactHasNoUser(List<Contact> contacts) {
        List<Contact> hasNoUser = new List<Contact>();
        if (!contacts.isEmpty()) {
            Set<Id> hasUsers =
                pluck.ids(
                    User.ContactId,
                    new QueryTrampoline().queryUsersForContacts(
                        pluck.ids(contacts)));
            for (Contact contactSobj: contacts) {
                if (!hasUsers.contains(contactSobj.Id)) {
                    hasNoUser.add(contactSobj);
                }
            }
        }
        return hasNoUser;
    }

    List<Opportunity> filterNewlyEnrolledWithContact(List<Opportunity> newOpptys, Map<Id, Opportunity> oldOpptysMap) {
        List<Opportunity> contactNowEnrolled = new List<Opportunity>();
        for (Opportunity newOppty: newOpptys) {
            if (
                    newOppty.Contact_Name__c != null &&
                    newOppty.StageName == STAGE_ENROLLMENT_COMPLETE &&
                    (
                        oldOpptysMap == null ||
                        oldOpptysMap.get(newOppty.Id).StageName != STAGE_ENROLLMENT_COMPLETE
                    )
                ) {
                contactNowEnrolled.add(newOppty);
            }
        }
        return contactNowEnrolled;
    }


    void markNeedsNewUser(List<Contact> contacts) {
        for (Contact contactSobj : contacts) {
            contactSobj.User_Needed_Datetime__c = System.now();
        }
    }

    void stampNeedsNewUserOnContact(List<Opportunity> opptys) {
        List<Contact> toUpdateIfHasNoUser = new List<Contact>();
        Map<Id, List<Opportunity>> opptysGroupedByContact = groupBy.ids(Opportunity.Contact_Name__c, opptys);
        for(Id contactId : opptysGroupedByContact.keySet()) {
            toUpdateIfHasNoUser.add(new Contact(
                Id = contactId,
                User_Needed_Datetime__c = System.now()
            ));
        }
        Map<Id, Contact> toUpdateMap = new Map<Id, Contact>(
            filterContactHasNoUser(toUpdateIfHasNoUser));
        DMLBox box = new DMLBox();
        for(Id contactId : opptysGroupedByContact.keySet()) {
            if(toUpdateMap.get(contactId) != null) {
                box.add(toUpdateMap.get(contactId), opptysGroupedByContact.get(contactId));
            }
        }
        box.safeUpdate();
    }

    without sharing class QueryTrampoline {
        public List<User> queryUsersForContacts(Set<Id> contactIds) {
            return [
                SELECT ContactId
                FROM User
                WHERE ContactId IN : contactIds
            ];
        }
    }

    without sharing class InsertTrampoline {
        public List<Database.SaveResult> insertUsersForContacts(List<User> usersForContacts) {
            return Database.insert(usersForContacts, false);
        }
    }
}