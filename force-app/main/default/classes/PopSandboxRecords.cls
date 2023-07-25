public class PopSandboxRecords {
    public static void PopSandboxRecords(){
    
    integer mynum = 1;
  //  mynum=2;
/*    
//   remove this line and the end star slash before running
       try {
             // get 4 random numbers
                Integer randomNumber = Integer.valueof((Math.random() * 10000));
                System.debug('randomNumber is'+randomNumber);
           
  //insert Organization  for employer & affiliation reference
  Account acct = new Account(Name= 'Employer ORg University '+randomNumber,type='Higher Education',Eligibility__c='Non-QCCO',EIN__c='55-5555555',phone='317.555.1212',
                             email__c='bmclarty+emporg@gmail.com',Organization_Status__c = 'Active',billingstate='TX',PA_Accepted_Date__c=date.newInstance(2018,05,22),PA_Effective_Date__c=date.newInstance(2018,05,29),
                             Participation_Plan_Agreement_Active__c='Yes'
                           );         
      insert acct;
    ID acctID = acct.ID;  
    String orgPIN = [SELECT PIN__c FROM Account WHERE Id = :acct.Id].PIN__c;
           
//insert contact        
    Contact con = new Contact(LastName='Bill'+randomNumber,Firstname='Will',MailingPostalCode=randomNumber+'99383',MailingState='IN',Phone='3177418520',mobilephone='9378521230',
                              email='bmclarty+sboxcontact'+randomNumber+'@gmail.com',Member_Type__c='Credentialed',
                          Contact_Type__c='Member',   Credentialed_Clergy_Type__c='Ordained',Annual_Salary__c=55555,Organization_Names__c = orgPIN,
                             RecordTypeId='012d0000000P39qAAC', User_ID__c='');
    insert con;
    ID conID = con.ID;
           
//insert affiliation           
           npe5__Affiliation__c aff1 = new npe5__Affiliation__c(npe5__Organization__c=acct.id,npe5__Contact__c=conid,npe5__StartDate__c=date.today());
          insert aff1; 
           
//insert contact  for beneficiary      priary 
    Contact conben1 = new Contact(LastName='Ben'+randomNumber,Firstname='Primary',MailingPostalCode=randomNumber+'99383',MailingState='IN',Phone='3177418520',mobilephone='9378521230',
                              email='bmclarty+sboxcontact'+randomNumber+'@gmail.com',RecordTypeId='012d0000000P39qAAC');
    insert conben1;
    ID conben1ID = conben1.ID;     
         
           
//insert contact  for beneficiary     contigent  
    Contact conben2 = new Contact(LastName='jamine'+randomNumber,Firstname='Contigent',MailingPostalCode=randomNumber+'99383',MailingState='IN',Phone='3177418520',mobilephone='9378521230',
                              email='bmclarty+sboxcontact'+randomNumber+'@gmail.com', RecordTypeId='012d0000000P39qAAC');
    insert conben2;
    ID conben2ID = conben2.ID;                
       
// Add a Checking bank account to this account.      
    bnk_Bank__c  bnk = new bnk_Bank__c( bnk_Account_Holder_Name__c = conID,
    bnk_Account_Number__c = '12345'+randomNumber,   bnk_Bank_Name__c = 'Test 123'+randomNumber,    bnk_Country__c = 'US',
    bnk_Is_Active__c    = TRUE,    bnk_Routing_Number__c    = '12345'+randomNumber, Checking_or_Savings__c = 'Checking');
       insert bnk;
// Add a Checking bank account to this account.      
    bnk_Bank__c  bnk2 = new bnk_Bank__c(    bnk_Account_Holder_Name__c = conID,
    bnk_Account_Number__c = '77745'+randomNumber,   bnk_Bank_Name__c = 'Test 456'+randomNumber,    bnk_Country__c = 'US',
    bnk_Is_Active__c    = false,    bnk_Routing_Number__c   = '12345'+randomNumber, Checking_or_Savings__c = 'Savings');
       insert bnk2;           
           
// add account summary AR-PF           
      Account_Summary__c acctARPF = new Account_Summary__c (
           name='AR-'+randomNumber,Member_Name__c = conid, Status__c = 'PF', Special_Apportionment_Credits__c=randomNumber/1000, recordtypeid='0120V000001tbfSQAQ',
       Account_Number__c ='AR-'+randomNumber,Total_Contributions__c=randomNumber*3,  Total_Withdrawals__c=randomNumber/5, Account_Type__c ='US Pension Plan',
                Account_Desc__c = 'Original Pension Account', Employee_Percentage__c=3, Employer_Percentage__c=11);
        insert acctARPF;   
// add account summary DB-C      
            randomNumber = Integer.valueof((randomNumber/2)*5);      
      Account_Summary__c acctDBC = new Account_Summary__c (
           name='DB-'+randomNumber,Member_Name__c = conid, Status__c = 'C', Special_Apportionment_Credits__c=randomNumber/1000, recordtypeid='0120V000001tbfSQAQ',
       Account_Number__c ='DB-'+randomNumber,Total_Contributions__c=randomNumber*3,  Total_Withdrawals__c=randomNumber/5, Account_Type__c ='US Pension Plan',
                Account_Desc__c = 'Original Pension Account', Employee_Percentage__c=0, Employer_Percentage__c=14);
        insert acctDBC;              

// add account summary DB-A      
            randomNumber = Integer.valueof((randomNumber/5)*3);      
      Account_Summary__c acctDBA = new Account_Summary__c (
           name='DB-'+randomNumber,Member_Name__c = conid, Status__c = 'A', Special_Apportionment_Credits__c=randomNumber/1000, recordtypeid='0120V000001tbfSQAQ',
       Account_Number__c ='DB-'+randomNumber,Total_Contributions__c=randomNumber*3,  Total_Withdrawals__c=randomNumber/5, Account_Type__c ='US Pension Plan',
                Account_Desc__c = 'Original Pension Account', Employee_Percentage__c=0, Employer_Percentage__c=14);
        insert acctDBA;              
// add account summary DB-PD      
            randomNumber = Integer.valueof((randomNumber/5)*3);      
      Account_Summary__c acctDBPD = new Account_Summary__c (
           name='DB-'+randomNumber,Member_Name__c = conid, Status__c = 'A', Special_Apportionment_Credits__c=randomNumber/1000, recordtypeid='0120V000001tb75',
       Account_Number__c ='DB-'+randomNumber,Total_Contributions__c=randomNumber*3,  Total_Withdrawals__c=randomNumber/5, Account_Type__c ='US Pension Plan',Total_Dues_Outstanding__c=555,
                Account_Desc__c = 'Original Pension Account', Employee_Percentage__c=0, Employer_Percentage__c=14);
        insert acctDBPD;              
                                            
           
           
           
           
 // add account summary TD-C    
    randomNumber = Integer.valueof((randomNumber/3)*4.2);       
      Account_Summary__c acctTDC = new Account_Summary__c (
           name='TD-'+randomNumber,Member_Name__c = conid, Status__c = 'C', Special_Apportionment_Credits__c=randomNumber/1000, recordtypeid='0120V000001tbgYQAQ',
             Account_Number__c ='TD-'+randomNumber,  Total_Contributions__c=randomNumber*3,  Total_Withdrawals__c=randomNumber/5, Account_Type__c ='Tax-Deferred 403(b) Retirement Account',
                Account_Desc__c = 'Employer Sponsored Renegotiatied Tax-Deferred Retirement Savings Account', Employee_Percentage__c=0, Employer_Percentage__c=0);
        insert acctTDC;             
           
 
// add account summary IRA-A    
    randomNumber = Integer.valueof((randomNumber/4)*2.2);       
      Account_Summary__c acctIRAA = new Account_Summary__c (
           name='IRA-'+randomNumber,Member_Name__c = conid, Status__c = 'A', Special_Apportionment_Credits__c=randomNumber/1000, recordtypeid='0120V000001tbfTQAQ',
            Account_Number__c ='IRA-'+randomNumber, Total_Contributions__c=randomNumber*3,  Total_Withdrawals__c=randomNumber/5, Account_Type__c ='Traditional IRA',
                Account_Desc__c = 'Traditional IRA Transferred Account', Employee_Percentage__c=0,  Employer_Percentage__c=0);
        insert acctIRAA; 
           
// add account summary BA-A    
    randomNumber = Integer.valueof((randomNumber/2)*6);       
      Account_Summary__c acctBAA = new Account_Summary__c (
           name='BA-'+randomNumber,Member_Name__c = conid, Status__c = 'A', Special_Apportionment_Credits__c=randomNumber/1000, recordtypeid='0120V000001tbgd',
           Account_Number__c ='BA-'+randomNumber, Total_Contributions__c=randomNumber*3,  Total_Withdrawals__c=randomNumber/5, Account_Type__c ='Benefit Accumulation Account',
                Account_Desc__c = 'Supplemental Savings Original Account', Employee_Percentage__c=0,    Employer_Percentage__c=0);
        insert acctBAA;    
       ID acctBAAID = acctBAA.ID;      
        // add Benificiary 1
            Beneficiary__c  ben1 = new Beneficiary__c (
                Contact__c=conben1ID,   Account_Summary__c=acctBAAID,   Beneficiary_Percentage__c=100,  Beneficiary_Type__c='Primary',  Type__c='Beneficiary'
                );
           insert ben1;
        // add Benificiary 2
            Beneficiary__c  ben2 = new Beneficiary__c (
                Contact__c=conben2ID,   Account_Summary__c=acctBAAID,   Beneficiary_Percentage__c=100,  Beneficiary_Type__c='Contingent',   Type__c='Beneficiary'
                );   
           insert ben2;

    }
        
    catch(DmlException e) {
    System.debug('An unexpected error has occurred: ' + e.getMessage());
    }
 
    */
    }      

}