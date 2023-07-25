public with sharing class PulsChkClsList{

/*This for backend dashboard PulsChkVFpageList VF page to be used by internal IT users. For more info pl contact Brandon McLarty*/ 
        
public List <Transaction__c> Transactions {get; set;}
public list <AggregateResult> AcctSummry { get; set; }
public list<SetupAuditTrail> AuditTrail { get; set; }
   
public PulsChkClsList(){
loaddata();   
}

public void loaddata()
{
    Transactions = new list<Transaction__c>();
    //AcctSummry = new list<Account_Summary__c>();
    AuditTrail = new list<SetupAuditTrail>();

/*List of Transactions created in Last 5 days */    
    Transactions =
[select id,name,CreatedDate, Account_Summary__c, Amount__c, Apply_Date__c, ContactId__c, IsDeleted, Period_Begin_Date__c, Period_End_Date__c  
from Transaction__c where CreatedDate  < today];

/*Duplicate Accounts created due to Jitterbit scripts. Notify Business users and thes recordes need to be deleted*/  
    
 AcctSummry  =
     [SELECT Account_Number__c acct, Count(Id) cnt
FROM Account_Summary__c 
GROUP BY Account_Number__c
HAVING Count(Id) > 1 limit 1000];
    
   /* for(AggregateResult result : aggregatecount)
    {
        //AcctSummry.add(result);  
        System.debug(result.get('Account_number__c'));
        System.debug(result.get('expr0'));
        
    }*/

    
 
    system.debug('Account summary list' +AcctSummry );
    
 /*Audit Trail of past 5 days exculding Password changes and Email Verification*/    

    AuditTrail=
[select Action, CreatedBy.Name, CreatedDate, Display, Section  from SetupAuditTrail where (not action like '%password%') and (not action like '%suNetworkAdminL%' ) 
and action <> 'changedUserEmailVerifiedStatusVerified'
And createddate = LAST_N_DAYS:5
order by CreatedDate desc limit 100];
    
}
}