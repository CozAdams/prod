public with sharing class FundListForEmailController {
	
	public Id currentPaymentId {get; set;}
	public pymt__PaymentX__c currentPayment {get{
		if(currentPayment == null) {
			currentPayment = [SELECT Id, In_Honor_Of_or_In_Memory_Of__c, Name_and_Address__c, pymt__Payment_Profile__r.pymt__Period__c,
				CreatedDate, pymt__Payment_Profile__r.In_Honor_Of_or_In_Memory_Of__c, pymt__Payment_Profile__r.Name_and_Address__c
                FROM pymt__PaymentX__c WHERE Id = :currentPaymentId LIMIT 1];
		}
		return currentPayment;
	}set;}

    public String inHonorMemoryOf {get {
        if (inHonorMemoryOf == null) {
            if(currentPayment.pymt__Payment_Profile__c == null) {
                inHonorMemoryOf = currentPayment.In_Honor_Of_or_In_Memory_Of__c;
            } else {
                inHonorMemoryOf = currentPayment.pymt__Payment_Profile__r.In_Honor_Of_or_In_Memory_Of__c;
            }
        }
        return inHonorMemoryOf;
    }set;}

    public String donationHonoree {get {
        if (donationHonoree == null) {
            if(currentPayment.pymt__Payment_Profile__c == null) {
                donationHonoree = currentPayment.Name_and_Address__c;
            } else {
                donationHonoree = currentPayment.pymt__Payment_Profile__r.Name_and_Address__c;
            }
        }
        return donationHonoree;
    }set;}

	public String frequency {get {
		if(frequency == null) {
			if(currentPayment.pymt__Payment_Profile__c == null) {
				frequency = 'One Time';
			} else {
                if (currentPayment.pymt__Payment_Profile__r.pymt__Period__c == 'Month') {
                    frequency = 'Monthly';
                } else if (currentPayment.pymt__Payment_Profile__r.pymt__Period__c == 'Year') {
                    frequency = 'Annually';
                }
			}
		} 
		return frequency;
	} set;}
	
	public List<pymt__Shopping_Cart_Item__c> shoppingCartItems {get {
		if(shoppingCartItems == null || shoppingCartItems.isEmpty()) {
			shoppingCartItems = [SELECT Id, Name, pymt__Total__c FROM pymt__Shopping_Cart_Item__c WHERE pymt__Payment__c = :currentPaymentId];
		}
		return shoppingCartItems;
	} set;}
}