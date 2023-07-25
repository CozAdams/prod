/*********************************************************************************************
Created By: John Wrightsman
Email: john.wrightsman@revelanttech.com
Created: 12/08/2017
Notes: Helper class which creates Pension_Contribution__c on the Case for each Transaction__c
    on the related Account_Summary__c. This was created to be called from a button the Case.
*********************************************************************************************/
global class CaseFetchPaymentsHelper {

    WebService static String remoteFetchPayments(Id caseId) {
        return fetchPayments(caseId);
    }

    @AuraEnabled
    public static String fetchPayments(Id caseId) {
        String result = '';

        try {
            Case oCase = [SELECT ContactId, Disability_Date__c FROM Case WHERE Id = :caseId];
            List<Account_Summary__c> accSummaries = [
                SELECT Id
                FROM Account_Summary__c
                WHERE Member_Name__c = :oCase.contactId
                AND Name LIKE 'DB%'
                AND Status__c IN ('A', 'IA')
                AND Account_Desc__c LIKE '%Orig%'
            ];

            if (accSummaries.size() > 0) {

                // Only create records for Transaction with an Apply Date within the past year
                // Or... If the case has a Disability Date, then only Transactions with an Apply Date within the
                // past year of the Disability Date.

                Date endDate = Date.today();
                Date beginDate = Date.today().addYears(-1);
                if (oCase.Disability_Date__c != null) {
                    endDate = oCase.Disability_Date__c;
                    beginDate = oCase.Disability_Date__c.addYears(-1);
                }

                List<Transaction__c> transactions = [
                    SELECT Account_Summary__c, Amount__c, Apply_Date__c, Option__c,
                        Period_Begin_Date__c, Period_End_Date__c, Type__c
                    FROM Transaction__c
                    WHERE Account_Summary__c IN :accSummaries
                    AND Apply_Date__c >= :beginDate
                    AND Apply_Date__c <= :endDate
                ];

                if (transactions.size() > 0) {
                    // Delete any existing Pension Contributions on the Case
                    List<Pension_Contribution__c> pensionContributions = [
                        SELECT Id
                        FROM Pension_Contribution__c
                        WHERE Case__c = :caseId
                    ];
                    if (pensionContributions.size() > 0) {
                        Delete pensionContributions;
                    }

                    // Create a Pension_Contribution__c for each Transaction__c and relate it to the Case
                    pensionContributions = new List<Pension_Contribution__c>();
                    for (Transaction__c trans : transactions) {
                        Pension_Contribution__c contrib = new Pension_Contribution__c(
                            Case__c = caseId,
                            Account_Summary__c = trans.Account_Summary__c,
                            Amount__c = trans.Amount__c,
                            Apply_Date__c = trans.Apply_Date__c,
                            Option__c = trans.Option__c,
                            Period_Begin_Date__c = trans.Period_Begin_Date__c,
                            Period_End_Date__c = trans.Period_End_Date__c,
                            Type__c = trans.Type__c
                        );
                        pensionContributions.add(contrib);
                    }
                    insert pensionContributions;
                }
            }

            oCase.Payment_Fetch_Date__c = Datetime.now();
            update oCase;
        } catch (Exception e) {
            result = e.getMessage();
        }

        return result;
    }
}