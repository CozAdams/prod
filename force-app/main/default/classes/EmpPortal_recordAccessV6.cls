public class EmpPortal_recordAccessV6 implements
    Database.Batchable<sObject>, Database.Stateful {
 
    public Integer AcctrecordsProcessed = 0;
    public Integer AcctrecordsExposed = 0;
        
    private String strParameter;
    public EmpPortal_recordAccessV6(String strParam) {
        strParameter = strParam;
    } 

        
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
     //       'SELECT ID, name from account where name like \'T%\''
           'SELECT ID, name from account'
        );
    }
                
    public void execute(Database.BatchableContext bc, List<Account> scope){
        // process each batch of records
       for (Account account : scope) {            
        string    AcId = account.id;
        string    AcName = Account.name;
    //    Id UID = [SELECT Id FROM User WHERE Name = 'Matt Millns'][0].Id;
    //    string UID = '0050V0000079em2';
     string UID = strparameter;
          // system.debug('USER ID: '+ UID);
            
             List<UserRecordAccess> Aacct = [select MaxAccessLevel,RecordId from UserRecordAccess where  UserId =: UID AND RecordID =: AcId ];
          
            for(UserRecordAccess URA: Aacct ) { 
                System.debug('URA: ' + URA);

           if(URA.MaxAccessLevel <> 'None'){
            	System.debug('HAS ACCESS--->>' + AcId + '	' + AcName);
               
               Employer_Portal_Exposed_Record__c er =  new Employer_Portal_Exposed_Record__c (
                   		Record_Name__c= AcName, 
                       RecordID__c = AcID,
                       User__c = UID,
                       MaxAccessLevel__c = URA.MaxAccessLevel,
                   		Organization__c = AcID,
                       Object__c = 'Account');
                 insert(er);
              AcctrecordsExposed = AcctRecordsExposed + 1;
            }                   
             AcctrecordsProcessed = AcctrecordsProcessed + 1;
           }
        }   
     
    }
     
    public void finish(Database.BatchableContext bc){
        System.debug(AcctrecordsProcessed + ' Account records exposed ');
       
    }
}


/*
 * PORTAL USERS
 * "_"	"Id"	"Name"	"Organization__c"
"[User]"	"0050V000007JHPjQAO"	"Wendy Yamada"	"30029612"
"[User]"	"0050V000007JHPyQAO"	"Tina Rickard"	"30028164"
"[User]"	"0050V000007vyduQAA"	"Karen Sturchio"	"30029980"
"[User]"	"0050V000007vyflQAA"	"Carol Burnley"	"30029711"
"[User]"	"0050V000007vyfqQAA"	"Rachel Clement"	"30025944"
"[User]"	"0050V000007vykMQAQ"	"Thaddaeus Allen"	"30029774"
"[User]"	"0050V000007vyuCQAQ"	"Jennifer Hunziker"	"30029666"
"[User]"	"0050V000007vyveQAA"	"James Ruddell"	"30029628"
"[User]"	"0050V000007vyz7QAA"	"Carol Fields"	"50064006"
"[User]"	"0050V000007vz5UQAQ"	"Bruce Indermill"	"30029638"
"[User]"	"0050V000007vz5jQAA"	"Kathy Flournoy"	"30029641"
"[User]"	"0050V000007vz5oQAA"	"Leslie Bean"	"30029616"
"[User]"	"0050V000007vz5tQAA"	"Robin Varner"	"30029595"
"[User]"	"0050V000007w0QnQAI"	"Sheetal Kammaje"	"50042636"
"[User]"	"0053o0000087m1xAAA"	"Amy Harrison"	"50200183"
"[User]"	"0053o0000087lzIAAQ"	"Emp Portal - do not Delete TEST RECORD"	"30029619"
"[User]"	"0053o0000087m14AAA"	"Brandon Rouse"	"50052877"
"[User]"	"0053o0000087m1sAAA"	"Wendy Garrett"	"50200183"
"[User]"	"0053o0000087m2vAAA"	"Kathy Burd"	"30029622"
"[User]"	"0053o0000087m30AAA"	"David Eversole"	"30028970"
"[User]"	"0053o0000087m43AAA"	"Diana Silva"	"30029637"
"[User]"	"0053o0000087m4hAAA"	"George Martin"	"50049187"  christian city
"[User]"	"0053o0000087m6EAAQ"	"Robert Morris"	"30029722"
"[User]"	"0053o0000087m6JAAQ"	"Rhonda Hopewell"	"30029663"
"[User]"	"0053o0000087m6dAAA"	"Lonna Owens"	"30029674"
"[User]"	"0053o0000087m77AAA"	"Linda Lafay"	"30029451"
"[User]"	"0053o0000087mViAAI"	"Beverly Darnell"	"30091783"
"[User]"	"0053o0000087mY3AAI"	"Dani Loving-Cartwright"	"30029699"
"[User]"	"0053o0000087mY8AAI"	"Chris Morton"	"30029711"
"[User]"	"0053o0000087mdcAAA"	"Tori Freeman"	"30029726"
"[User]"	"0053o0000087miNAAQ"	"Monique Macias"	"30029821"
"[User]"	"0053o0000087mjBAAQ"	"Michelle Whiteley"	"30029619"
"[User]"	"0053o0000087mjGAAQ"	"Tracy Thompson"	"30029619"
"[User]"	"0053o0000087mjLAAQ"	"Reggie Hendricks"	"30029619"
"[User]"	"0053o0000087mqlAAA"	"Todd Barcroft"	"30029737"
"[User]"	"0050V000006Yba9QAC"	"William Bauer"	"30029575"
"[User]"	"0050V0000079gmnQAA"	"Vickie Gabriel"	"30029636"
"[User]"	"0053o000007wOp7AAE"	"Bob Test - Emp Portal - Radhika"	"50211059"
"[User]"	"0050V000006YeLbQAK"	"Nicole Porter EP"	"30029783"
"[User]"	"0050V0000079em2QAA"	"Matt Millns"	"30029619"   tcu
"[User]"	"0050V0000078f3kQAA"	"Bob Test -Employer Portal MGR"	"50211059"

*/