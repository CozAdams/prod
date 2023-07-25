public without sharing class AccountSummaryService {
    private static String IRA_ACC_TYPE = 'Traditional IRA';
    private static String ROTH_ACC_TYPE = 'Roth IRA';
    private static String TDRA_ACC_TYPE = 'Tax-Deferred 403(b) Retirement Account';
    private static String TDRA_PR_ACC_TYPE = 'Tax-Deferred 403(b) Retirement Account Puerto Rico';
    @testVisible private static Integer X457_MIN_WITHDRAW_AGE = 72;

    @AuraEnabled
    public static Map<String, String> getCountries() {
        Map<String, String> countriesISOToLabel = new Map<String, String>();
        List<Country__c> countries = Country__c.getAll().values();
        for (Country__c country : countries) {
            countriesISOToLabel.put(country.ISO__c, country.Label__c);
        }
        return countriesISOToLabel;
    }

    @AuraEnabled
    public static Map<String, String> getStates(String countryISO) {
        Map<String, String> statesISOToLabel = new Map<String, String>();
        List<State__c> states = State__c.getAll().values();
        for (State__c state : states) {
            if (state.CountryISO__c == countryISO) {
                statesISOToLabel.put(state.ISO__c, state.Label__c);
            }
        }
        return statesISOToLabel;
    }

    @AuraEnabled
    public static List<Account_Summary__c> getAccountSummaryList(Id contactId, Account_Summary__c currentAccount) {
        return [
            SELECT Id, Name, Account_Desc__c 
            FROM Account_Summary__c 
            WHERE Member_Name__c = :contactId 
            AND Account_Type__c = :currentAccount.Account_Type__c
            AND Id != :currentAccount.Id 
            AND Account_Desc__c = :currentAccount.Account_Desc__c
            AND Status_display__c != 'Closed'
        ];
    }

    @AuraEnabled
    public static List<Account_Summary__c> getAccountSummaryListTDRA(Id contactId) {
        return [
            SELECT Id, Name, Balance__c
            FROM Account_Summary__c 
            WHERE Member_Name__c = :contactId 
            AND Plan_ID__c = '403BTRAD'
            AND Status_display__c != 'Closed'
        ];
    }

    /*******************************************************************************************************
    * @description  Get total amount member has contributed for specified account types and year
    * @param        contactId - member ID
    * @param        accountSummaryType - type of Account Summary to check against
    * @param        yearParam - tax year to check against
    * @return       amount member has contributed so far
    */
    @AuraEnabled
    public static Decimal getTotalContributionsSoFar(Id contactId, String accountSummaryType, Decimal yearParam) {
        // Values for query
        Date todaysDate = Date.today();
        Integer year = Integer.valueOf(yearParam);

        List<String> accountTypes = new List<String>();
        if (accountSummaryType.equals(IRA_ACC_TYPE) || accountSummaryType.equals(ROTH_ACC_TYPE)) {
            accountTypes.add(IRA_ACC_TYPE);
            accountTypes.add(ROTH_ACC_TYPE);
        }
        else if (accountSummaryType.equals(TDRA_ACC_TYPE) || accountSummaryType.equals(TDRA_PR_ACC_TYPE)) {
            accountTypes.add(TDRA_ACC_TYPE);
            accountTypes.add(TDRA_PR_ACC_TYPE);
        }
        else {
            accountTypes.add(accountSummaryType);
        }
        
        // Retrieve existing contribution records by year and account type
        String queryString = 'SELECT Id,' +
            ' (SELECT Id, Amount__c FROM Transactions__r' +
                ' WHERE Calendar_Year__c = :year' + 
                ' AND Type__c = \'Contribution\'),' +
            ' (SELECT Id, Contribution_Day__c, Start_Date__c, End_Date__c, Amount__c, Frequency__c' +
                ' FROM Recurring_Contributions__r' +
                ' WHERE CALENDAR_YEAR(Start_Date__c) <= :year' +
                ' AND Active__c = TRUE)' +
            ' FROM Account_Summary__c' +
            ' WHERE Member_Name__c = :contactId' +
            ' AND Account_Type__c IN :accountTypes';

        // IRA types should only count Original account contributions
        if (accountSummaryType.equals(IRA_ACC_TYPE) || accountSummaryType.equals(ROTH_ACC_TYPE)) {
            queryString += ' AND Account_Desc__c LIKE \'%Original%\'';
        }
        // TDRA types should only count Renegotiated and Over and Above account contributions 
        if (accountSummaryType.equals(TDRA_ACC_TYPE) || accountSummaryType.equals(TDRA_PR_ACC_TYPE)) {
            // List<String> tdraTypes = new List<String>{ '%Renegotiated%', '%Over and Above%' };
            // queryString += ' AND Account_Desc__c LIKE :tdraTypes';
            queryString += ' AND Account_Desc__c LIKE \'%Renegotiated%\'';
        }

        // Query existing contributions and sum the total contribution amount
        List<Account_Summary__c> summariesWithRecurringContributions = Database.query(queryString);
        
        // Calculate current contribution total
        Decimal totalContributed = 0.00;
        for(Account_Summary__c summary : summariesWithRecurringContributions) {
            for(Recurring_Contributions__c recurringContribution : summary.Recurring_Contributions__r) {
                if(recurringContribution.Frequency__c == 'Monthly') {
                    Date endDate = recurringContribution.End_Date__c;
                    Date startDate = recurringContribution.Start_Date__c;

                    if(todaysDate.year() == year){
                        if(startDate < todaysDate) {
                            startDate = todaysDate;
                        }
                        if(endDate == null) {
                            endDate = Date.newInstance(todaysDate.year(), 12, 31);
                        }
                    }
                    Integer monthsLeft = endDate.month() - startDate.month() + 1;
                    if (monthsLeft <= 0) {
                        continue; // All of the recurring payments have been made
                    }

                    Integer contributionDay = 1;
                    if (recurringContribution.Contribution_Day__c == 'Fifteenth') {
                        contributionDay = 15;
                    }
                    //if the start day happens AFTER the contribution day, we have already contributed to the total.
                    if(startDate.day() > contributionDay) {
                        monthsLeft -= 1;
                    }

                    //if the end day happens BEFORE the contribution day, we have already contributed to the total.
                    if(endDate.day() < contributionDay) {
                        monthsLeft -= 1;
                    }

                    totalContributed += monthsLeft * recurringContribution.Amount__c;
                } else if(recurringContribution.Frequency__c == 'Annually') {
                    totalContributed += recurringContribution.Amount__c;
                }
            }
            for(Transaction__c trans : summary.Transactions__r) {
                totalContributed += trans.Amount__c;
            }
        }
        
        return totalContributed;
    }

    /*******************************************************************************************************
    * @description  Get configured contribution limits for specified account type and years
    * @param        accountType - Type of Account Summary
    * @param        years - Years to retrieve limits for
    * @return       list of contribution limit metadata records
    */
    @AuraEnabled
    public static List<Contribution_Limit__mdt> getMaxContributionLimits(String accountType, List<String> years) {
        // Get stored limits from custom metadata for the account type and years
        List<Contribution_Limit__mdt> storedLimits = [
            SELECT Retirement_Age__c, Amount_at_Retirement_Age__c, Amount_Before_Retirement_Age__c, Year__c
            FROM Contribution_Limit__mdt
            WHERE Year__c IN :years
            AND Account_Type__c = :accountType
        ];
        return storedLimits;
    }

    @AuraEnabled
    public static User getUser() {
         return [SELECT Id, FirstName, LastName, ContactId, Contact.FirstName, Contact.LastName, Contact.Marital_Status__c, Contact.Age__c
                    FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }

    @AuraEnabled
    public static List<bnk_Bank__c> getBankingInformationList(Id contactId) {
         return [
            SELECT Id, bnk_Bank_Name__c, bnk_Account_Number__c, Bank_Account_Country__c 
            FROM bnk_Bank__c
            WHERE bnk_Account_Holder_Name__c = :contactId 
            AND bnk_Is_Active__c = TRUE
        ];
    }

    @AuraEnabled
    public static Id getCaseQueue() {
         return [SELECT Id FROM Group WHERE DeveloperName = 'Online_Transactions' AND Type = 'Queue'].Id;
    }

    @AuraEnabled
    public static Id getCaseRecordType() {
         return [SELECT Id FROM RecordType WHERE DeveloperName = 'Online_Transactions' AND SobjectType = 'Case'].Id;
    }

    @AuraEnabled
    public static Account_Summary__c getAccountSummary(Id accountSummaryId) {
         return [
             SELECT Id, Balance__c, Member_Name__r.Id, Member_Name__r.Age__c, Member_Name__r.MailingStreet, 
                 Member_Name__r.MailingCity, Member_Name__r.MailingState, 
                 Member_Name__r.MailingPostalCode, Current_Monthly_Dues__c, 
                 Total_Dues_Outstanding__c, Account_Type__c, RecordType.DeveloperName,Plan_ID__c,Accrued_Interest__c,
                 Organization__c, Account_Desc__c, 
                (SELECT Id, Apply_Date__c FROM Transactions__r WHERE Type__c = 'withdrawal') 
            FROM Account_Summary__c 
            WHERE Id = :accountSummaryId 
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static Integer getWithdrawalCountForMonth(Id accountSummaryId) {
        Integer transactionCount = [
            SELECT COUNT() 
            FROM Transaction__c
            WHERE Account_Summary__c = :accountSummaryId
            AND Type__c = 'withdrawal'
            AND Apply_Date__c = THIS_MONTH
        ];
        return transactionCount;
    }

    @AuraEnabled
    public static Boolean getPermissionToWithdraw(Id orgId) {
        Boolean withdrawPermitted = true;
        User u = [SELECT Contact.Id, Contact.Age__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        if (u.Contact.Age__c == null || u.Contact.Age__c < X457_MIN_WITHDRAW_AGE) {
            npe5__Affiliation__c affiliation = [
                SELECT Id, Calculated_Status__c
                FROM npe5__Affiliation__c
                WHERE npe5__Organization__c = :orgId
                AND npe5__Contact__c = :u.ContactId
                LIMIT 1
            ];
            
            if (affiliation.Calculated_Status__c == 'Active') {
                withdrawPermitted = false;
            }
        }
        return withdrawPermitted;
    }

    @AuraEnabled
    public static Id saveBankAccount(bnk_Bank__c newBankAccount) {
        try{
            insert newBankAccount;
        } catch(DmlException e) {
            throw new AuraHandledException('An error occurred when inserting a new bank account please contact an Administrator. Error : ' + getDmlErrorMessage(e));
        }

        return newBankAccount.Id;
    }

    @AuraEnabled
    public static void saveCase(Case currentCase) {
        try{
            insert currentCase;
        } catch(DmlException e) {
            throw new AuraHandledException('An error occurred when inserting a new case please contact an Administrator. Error : ' + getDmlErrorMessage(e));
        }
    }

    private static String getDmlErrorMessage(DmlException e)
    {
        String errorMessage = '';
        for(Integer i = 0; i < e.getNumDml(); i++){
            if(String.isNotBlank(errorMessage)){
                errorMessage += '\n';
            }
            errorMessage += e.getDmlMessage(i);
        }
        return errorMessage;
    }
}