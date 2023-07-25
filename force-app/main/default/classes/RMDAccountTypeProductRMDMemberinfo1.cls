public class RMDAccountTypeProductRMDMemberinfo1 {

  public List<Contact> contactinfo{get;set;} 
    public RMD_Account_Type__c productrmdID {get;set;} 
    public RMD_Account_Type__c memberinfo {get;set;}      

    //Constructor 

    public RMDAccountTypeProductRMDMemberinfo1(ApexPages.StandardController controller) { 

        productrmdID = (RMD_Account_Type__c)controller.getRecord();      

        memberinfo = [SELECT id, Contact__c,contact__r.name, contact__r.pin__c
                    FROM RMD_Account_Type__c
                    WHERE id = 'a0IK000000hD9QJMA0' LIMIT 1]; 

    
} 
}