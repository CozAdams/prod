public without sharing class RetirementCalculatorCont {

    @AuraEnabled
    public static Retirement_Calculator_Setting__mdt retrieveCalculatorSetting() {
        List<Retirement_Calculator_Setting__mdt> calculatorSettings = [SELECT Salary_Upper_Bounds__c, Salary_Upper_Bounds_Err__c,
				Salary_Lower_Bounds__c, Salary_Lower_Bounds_Err__c, Salary_Percentage_Lower_Bound__c, Salary_Percentage_Lower_Bound_Err__c,
				Salary_Percentage_Upper_Bound__c, Salary_Percentage_Upper_Bound_Err__c FROM Retirement_Calculator_Setting__mdt WHERE DeveloperName = 'Default' LIMIT 1];
        return calculatorSettings.get(0);
    }

	@AuraEnabled
	public static Contact retrieveRunningUserContact(){
        Id userId = UserInfo.getUserId();
        User u = [SELECT ContactId FROM User WHERE Id = :userId];
		return [SELECT Name, Birthdate, Annual_Salary__c, Age__c, Pension_Credits__c, DB_Membership_Status__c, Retirement_Date__c,
				Special_Apportionment_Credits__c, Total_Credits__c, Late_Retirement_Credits__c, PIN__c FROM Contact WHERE Id = :u.ContactId];
	}

	@AuraEnabled
	public static String getAvatarURL(){
        Id userId = UserInfo.getUserId();
		return [SELECT SmallPhotoUrl FROM User WHERE Id = :userId].SmallPhotoUrl;
	}

	@AuraEnabled
	public static void saveCalculations(Save_Retirement_Calculations__c newCalc){
        List<Save_Retirement_Calculations__c> calcs = [SELECT id FROM Save_Retirement_Calculations__c WHERE Name = :newCalc.Name];
        Save_Retirement_Calculations__c calc = newCalc;
        if (calcs.size() > 0) {
            calc = calcs[0]; // we only expect 1
            calc.Annual_Salary__c = newCalc.Annual_Salary__c;
            calc.Credit_Balance__c = newCalc.Credit_Balance__c;
            calc.Desired_Retirement_Date__c = newCalc.Desired_Retirement_Date__c;
            calc.Monthly_Pension_Credits__c = newCalc.Monthly_Pension_Credits__c;
            calc.Projection_Date__c = newCalc.Projection_Date__c;
            calc.Salary_Percentage_Increase__c = newCalc.Salary_Percentage_Increase__c;
        }
		try{
			upsert calc;
		} catch (DmlException ex){
			handleDmlException(ex);
		}
	}

	@AuraEnabled
	public static void deleteCalculations(String calculationId) {
		Save_Retirement_Calculations__c calc = new Save_Retirement_Calculations__c(Id = calculationId);
        try {
            delete calc;
        } catch(DmlException ex) {
            handleDmlException(ex);
        }
	}

	@AuraEnabled
	public static List<Save_Retirement_Calculations__c> loadCalculations(){
        Id userId = UserInfo.getUserId();
        User u = [SELECT ContactId FROM User WHERE Id = :userId];
        return [SELECT Id, Name, CreatedDate, Annual_Salary__c, Desired_Retirement_Date__c, Monthly_Pension_Credits__c, Salary_Percentage_Increase__c
            FROM Save_RetireMent_Calculations__c WHERE Contact__c = :u.ContactId ORDER BY Name];
	}

	// Handling for DmlExceptions in Lightning
	private static void handleDmlException(DmlException ex){
	    String errorMessage = '';
	    for(Integer i = 0; i < ex.getNumDml(); i++){
	        if(String.isNotBlank(errorMessage)){
	            errorMessage += '\n';
	        }
	        errorMessage += ex.getDmlMessage(i);
	    }
	    throw new AuraHandledException(errorMessage);
	}	
}