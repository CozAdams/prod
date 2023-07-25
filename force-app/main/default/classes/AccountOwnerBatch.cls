/*********************************************************************************************
Created By: Khushboo Modi
Email: khushboo.modi@revelanttech.com
Created: 30/11/2016
Notes: This is a batch job to update the account owner based on the territory assignment rules.
*********************************************************************************************/

global class AccountOwnerBatch implements Schedulable, Database.Batchable<sObject> {
    
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('--- start');
        Database.Querylocator query;
        query = Database.getQueryLocator([select Id,Exclude_from_Territories__c,ownerId from Account]);
        return query;
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) { 
        system.debug('--- execute'); 
        List<Account> accounts = (List<Account>)scope;
        List<Account> toUpdate = new List<Account>();
        
        //gather a list of IDs from account
        List<Id> accountIds = new List<Id>();
        for(Account acct : accounts) {
            accountIds.add(acct.Id);
        }
        
        //get all AccountShares
        List<AccountShare> accountShares = [SELECT AccountId, Id, RowCause, UserOrGroupId 
                                            FROM AccountShare 
                                            where (RowCause = 'Territory' 
                                                   or RowCause = 'TerritoryManual') 
                                            and AccountId in :accountIds];
        
        //gather list of all groups
        List<Id> groupIds = new List<Id>();
        for(AccountShare ash : accountShares) {
            groupIds.add(ash.UserOrGroupId);
        }
        
        //get all Groups
        List<Group> groups = [select id, RelatedId from Group where Id in :groupIds];
        
        //gather list of all territory ids
        List<Id> territoryIds = new List<Id>();
        for(Group gr : groups) {
            territoryIds.add(gr.RelatedId);
        }
        
        //get all territories
        List<UserTerritory2Association> territoryAssignments = [SELECT Id,RoleInTerritory2, UserId, Territory2Id 
                                                                FROM UserTerritory2Association 
                                                                where Territory2Id in :territoryIds];
        
        //filter through Ids to assign user         
        for(Account acct : accounts) {
            if(!acct.Exclude_from_Territories__c) {
                for(AccountShare ash : accountShares) {
                    if(ash.AccountId == acct.Id) {
                        for(Group grp : groups) {
                            if(grp.Id == ash.UserOrGroupId) {
                                //get all associations for the territory
                                List<UserTerritory2Association> subsetUta = new List<UserTerritory2Association>();
                                
                                for(UserTerritory2Association uta : territoryAssignments) {
                                    if(uta.Territory2Id == grp.RelatedId) {
                                        subsetUta.add(uta);
                                    }
                                }
                                
                                if(!subsetUta.isEmpty()) {
                                    //if only one exists, use it regardless.
                                    if(subsetUta.size() == 1) {
                                        acct.OwnerID = subsetUta[0].UserId;
                                        toUpdate.add(acct);
                                        system.debug('Condition1 - Account Owner ID changed: ' + acct.Name + ' , ' + subsetUta[0].UserId);
                                    }
                                    else {
                                        Boolean foundManager = false; 
                                        
                                        for(UserTerritory2Association uta : subsetUta) {
                                            if(uta.RoleInTerritory2 == 'Account Executive') {
                                                acct.OwnerID = uta.UserId;
                                                toUpdate.add(acct);
                                                system.debug('Condition2 - Account Owner ID changed: ' + acct.Name + ' , ' + subsetUta[0].UserId);
                                                foundManager = true;
                                                break;
                                            }
                                        } 
                                        
                                        if(!foundManager) {
                                            acct.OwnerID = subsetUta[0].UserId;
                                            toUpdate.add(acct);
                                            system.debug('Condition3 - Account Owner ID changed: ' + acct.Name + ' , ' + subsetUta[0].UserId);
                                        }
                                    }                            
                                }
                                break;
                            }
                        }
                        break;
                    }
                }
            } /*else {
                
            }*/
        }
        
        system.debug('--- updated ' + toUpdate.size() + ' accounts.');
        try {
            update toUpdate;
        } catch(Exception e) {
            system.debug('*******************error: ' + e);
        }
        
        
        /*List<Id> updatedAcctIds = new List<Id>();
        for(account acc: toUpdate){
            updatedAcctIds.add(acc.Id);
        }*/
        
        List<Contact> toUpdateContacts = [select Id,OwnerId, AccountId from contact where Exclude_from_Territories__c =: false and AccountId IN: accountIds];
        for(contact con: toUpdateContacts){
            for(account acc: accounts){
                if(con.AccountId.equals(acc.Id)){
                    con.OwnerId = acc.ownerId;
                }
            }
        }
        try {
            update toUpdateContacts;
        } catch(Exception e) {
            system.debug('*******************error: ' + e);
        }
        
        
    }
    
    global void finish(Database.BatchableContext BC) {
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(this, 10);
    }
}