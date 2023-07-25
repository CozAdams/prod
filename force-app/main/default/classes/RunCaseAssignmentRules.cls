public class RunCaseAssignmentRules {

    @InvocableMethod
    public static void assignCases(List<Id> CaseIds){
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = TRUE;
        List<Case> toAssign = [SELECT Id FROM Case WHERE Id = :CaseIds];
        Database.update(toAssign,dmo);
    }
    
}