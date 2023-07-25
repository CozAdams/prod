public with sharing class ParentRelatedListGenerateServices {
    public void populateOrganizationOnContact(List<npe5__Affiliation__c> newRecords) {
        List<Contact> contactToUpdate = new List<Contact>();
        Map<Id, List<npe5__Affiliation__c>> contactIdToAffiliation =
            Groupby.ids(Npe5__Affiliation__c.Npe5__Contact__c,[
                SELECT npe5__Organization__r.PIN__c,
                    Npe5__Contact__c
                FROM Npe5__Affiliation__c
                WHERE Npe5__Contact__c IN: Pluck.ids(Npe5__Affiliation__c.Npe5__Contact__c, newRecords)]);
        for(Id contactId : contactIdToAffiliation.keySet()) {
            List<String> orgPINs = new List<String>(
                Pluck.strings('npe5__Organization__r.PIN__c', contactIdToAffiliation.get(contactId)) );

            contactToUpdate.add(new Contact(
                Id = contactId,
                Organization_Names__c = String.join(orgPINs, ' , ')
            ));
        }
        List<Database.SaveResult> results = Database.update(contactToUpdate, false);
        for(Database.SaveResult result : results) {
            if(!result.isSuccess()) {
                Id failureId = result.getId();
                for(npe5__Affiliation__c newRecord : newRecords) {
                    if(newRecord.Npe5__Contact__c == failureId) {
                        newRecord.addError('The organization PIN failed to populate onto the parent contact.');
                    }
                }
            }
        }

    }
}