@isTest
private class HousingAllowanceTest {
    @isTest static void testControllerBadParams() {
        PageReference pageRef = Page.HousingAllowance2020;
        Test.setCurrentPage(pageRef);
        
        HousingAllowance controller = new HousingAllowance();
        
        //fail if no params specified
        controller.initialize();
        System.assert(verifyPageMessage(HousingAllowance.MSG_BAD_PARAMETERS));
        
        //fail if params are set but don't find a matching contact
        ApexPages.currentPage().getParameters().put('contactRecordId', 'AAAA');
        ApexPages.currentPage().getParameters().put('pin', '1234');
        controller.initialize();
        System.assert(verifyPageMessage(HousingAllowance.MSG_NO_MATCHING_CONTACT));
    }

    @isTest static void testControllerMatchingContact() {
        PageReference pageRef = Page.HousingAllowance;
        Test.setCurrentPage(pageRef);
        
        HousingAllowance controller = new HousingAllowance();
        
        //set up a Contact and it should initialize with no messages
        Contact c = new Contact();
        c.LastName = 'Smithy';
        c.DDI_ID__c = '1237';
        c.Contact_Type__c = 'Member';
        c.Contact_Sub_Type__c = 'Original';
        c.Gender__c = 'F';
        c.Member_Type__c = 'Former Credentialed';
        c.Social_Security_Number__c = '111-11-1112';
        c.SSN_Verification_Required__c = FALSE;
        insert c;
        
        ApexPages.currentPage().getParameters().put('contactRecordId', c.Id);
        ApexPages.currentPage().getParameters().put('pin', c.DDI_ID__c);
        controller.initialize();
        
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        System.debug(msgs);
        System.assert(msgs.size() == 0);
        
        //but when we submit the error will be no designation set
        controller.submitHousingAllowance();
  //      System.assert(verifyPageMessage(HousingAllowance.MSG_NO_DESIGNATION));
        
        //set the designation but include a percent out of range for the 2nd and a bad percent value for the 3rd one
        controller.pensionCustomPercentage = '10';
        controller.tdraCustomPercentage = '120';
        controller.submitHousingAllowance();
        controller.annuityCustomPercentage = 'NOT VALID';
        controller.submitHousingAllowance();
  //      System.assert(verifyPageMessage(HousingAllowance.MSG_INVALID_PERCENTAGE));
        
        //if either TDRA or Annuity is set then Pension must be 100%
        controller.tdraCustomPercentage = '20';
        controller.annuityCustomPercentage = '30';
        controller.submitHousingAllowance();
  //     System.assert(verifyPageMessage(HousingAllowance.MSG_100_PERCENT_TO_ALLOCATE));
        
        //correct the percentages and the message will be for term acceptance and signature required
        controller.pensionCustomPercentage = '100';
        controller.submitHousingAllowance();
  //      System.assert(verifyPageMessage(HousingAllowance.MSG_NO_TERM_ACCEPT_AND_SIGNATURE));
        
        //accept the terms and fill in the signature and the message should be success and the form should no longer display
        controller.acceptTerms = true;
        controller.signature = 'Test Signature';
        controller.submitHousingAllowance();
   //     System.assert(verifyPageMessage(HousingAllowance.MSG_SUCCESS));
    }
    
    //check to see if the expected String was added as a page message and return true if it was, false if it was not added
    private static Boolean verifyPageMessage(String messageToVerify) {
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        for(Apexpages.Message msg : msgs) {
            if (msg.getDetail().contains(messageToVerify)) {
                return true;
            }
        }
        return false;
    }
}