/***************************************************************************************************
Name        : HousingAllowance
Created By  : Steve Shrader, Revelant Technologies
Email       : steve.shrader@revelanttech.com
Created Date: December 2015
Description : control and present data for use with HousingAllowance.page
Changes:
11-2-2016 jason.coleman@revelanttech.com - updated dates to 2017
9-28-2017 jason.coleman@revelanttech.com - updated dates to 2018
11-16-2017 john.wrightsman@revelanttech.com - updates to show conditional text for Commissioned clergy
10/18/2018 tweaver@pensionfund.org - updated dates to 2019
******************************************************************************************************/

/*************
updated by brandon mclarty 09/25/2019
    updated year display
    set pensionConvertedFromString = 100
    
*****************/    
public class HousingAllowance {
    public String contactRecordId {get;set;}
    public String pin {get;set;}
    public Contact contactRecord {get;set;}
    public Boolean displayForm {get;set;}
    @testvisible private static final String MSG_BAD_PARAMETERS = 'contactRecordId and pin are required parameters for this page.';
    @testvisible private static final String MSG_NO_MATCHING_CONTACT = 'Your information could not be found.  Please call 866-495-7322 or email PFCC1@Pensionfund.org';
    @testvisible private static final String MSG_NO_DESIGNATION = 'You have not designated an amount for your 2020 Housing Allowance. You must identify an amount to complete this Housing Allowance request form.';
    @testvisible private static final String MSG_INVALID_PERCENTAGE = 'Values entered must be between 0 and 100.';
    @testvisible private static final String MSG_100_PERCENT_TO_ALLOCATE = '100% of your pension must be designated in order to allocate TDRA or Annuity.';
    @testvisible private static final String MSG_NO_TERM_ACCEPT_AND_SIGNATURE = 'Please sign and agree to the terms above.';
    @testvisible private static final String MSG_SUCCESS = 'Thank you for your submission of your 2020 Housing Allowance designation. Pension Fund will now record this amount as your 2020 Housing Allowance.';

    //inputs to designate a percentage between 0 and 100
    public String pensionCustomPercentage = '100';
    public String tdraCustomPercentage {get;set;}
    public String annuityCustomPercentage {get;set;}

    //inputs to finish the submission
    public Boolean acceptTerms {get;set;}
    public String signature {get;set;}


    //called by a page parameter to set up needed information
    public void initialize() {
        displayForm = true;
        contactRecordId = ApexPages.currentPage().getParameters().get('contactRecordId');
        pin = ApexPages.currentPage().getParameters().get('pin');

        if(String.isBlank(contactRecordId) || String.isBlank(pin)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, MSG_BAD_PARAMETERS));
            displayForm = false;
        }
        else {
            List<Contact> contactList = [SELECT Id, Name, Home_Address_Street_1__c, Home_Address_Street_2__c, Home_Address_City__c, Home_Address_State_Province__c, Home_Address_Zip__c, FirstName, LastName, Credentialed_Clergy_Type__c
                                         FROM Contact
                                         WHERE Id = :contactRecordId AND PIN__c = :pin];
            if(contactList == null || contactList.size() != 1) {    //there should be exactly 1 matching record for Id and pin
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, MSG_NO_MATCHING_CONTACT));
                displayForm = false;
            }
            else {
                contactRecord = contactList[0];
            }
        }
    }

    //submit the checkboxes, percentages and signature for review and save or error reply
    public void submitHousingAllowance() {
        Integer pensionConvertedFromString;
        Integer tdraConvertedFromString;
        Integer annuityConvertedFromString;
        pensionConvertedFromString = 100;
       
        //check if the Pension Designation has been completed
        //it will fail if
        //  1. no text was entered for Pension Designate...the only required percentage
  
  //      if(String.isBlank(pensionCustomPercentage))
  //      {
           
  //          ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, MSG_NO_DESIGNATION));
  //          return;
  //      }
 
        //check if the Pension Designation has a valid percent entered
        //it will fail if
        //  1. any Percents were entered not between 0 and 100
        try {
          
            pensionConvertedFromString = validatePercentRange(pensionCustomPercentage);
            tdraConvertedFromString = validatePercentRange(tdraCustomPercentage);
            annuityConvertedFromString = validatePercentRange(annuityCustomPercentage);
        }
        catch(Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, MSG_INVALID_PERCENTAGE));
            return;
        }

        //check if any values were entered for TDRA or Annuity then Pension must be 100%
        if(!(tdraConvertedFromString == null || tdraConvertedFromString == 0) || !(annuityConvertedFromString == null || annuityConvertedFromString == 0)) {
            if(pensionConvertedFromString != 100) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, MSG_100_PERCENT_TO_ALLOCATE));
                return;
            }
        }

        //check if the form conditions were accepted and the signature completed
        //it will fail if
        //  1. acceptTerms was not checked
        //  2. signature is Blank
        if(acceptTerms == false || String.isBlank(signature))
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, MSG_NO_TERM_ACCEPT_AND_SIGNATURE));
            return;
        }

        //try to save the Contact record with the amounts selected and the signature
        try {
            contactRecord.HA_Pension__c = pensionConvertedFromString;
            contactRecord.HA_TDRA__c = tdraConvertedFromString;
            contactRecord.HA_Annuity__c = annuityConvertedFromString;
            contactRecord.HA_Signature__c = signature;
            contactRecord.HA_2015_Signed_Date__c = Datetime.now();
            upsert contactRecord;
        }
        catch(Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Problem saving the data. ' + e));
            return;
        }

        //everything was successful if this was reached.  display the success message but not the form
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, MSG_SUCCESS));
        displayForm = false;
        return;
    }

    //Percent String must be an Integer between 0 and 100
    //  return null if the String isBlank
    //  return the Integer value if it is no Blank
    //  throw an Exception if it's not in range 0 and 100
    private Integer validatePercentRange(String percent) {
        Integer converted = null;
        if(String.isNotBlank(percent)) {
            converted = Integer.valueOf(percent);
            if(converted < 0 || converted > 100) {
                throw new HousingAllowanceException('Percent must be between 0 and 100');
            }
        }
        return converted;
    }

    //an inner class Exception that can be created and thrown locally
    private class HousingAllowanceException extends Exception {}
}