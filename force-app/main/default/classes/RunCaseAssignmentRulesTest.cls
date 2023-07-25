/**
* @author Lev
* @date 2020
*
* @description Test class RunCaseAssignmentRules
*/
@IsTest
public with sharing class RunCaseAssignmentRulesTest {
    /* TEST DATA */
    static Case case1;
    static Case case2;

    //* TEST DATA INITIALIZATION *//
    static void init() {
        case1 = TestDataFactory.createCase(true);
        case2 = TestDataFactory.createCase(true);
    }

    /* TEST METHODS */
    @isTest
    static void testAssignCases_success() {
        init();

        // Test
        System.Test.startTest();
        RunCaseAssignmentRules.assignCases(new List<Id>{ case1.Id, case2.Id });
        System.Test.stopTest();

        // Post-test
        List<Case> updatedCases = [SELECT Id, OwnerId FROM Case];

        // Assert that the assignment rules updated the Cases
        for (Case c : updatedCases) {
            System.assertNotEquals(UserInfo.getUserId(), c.OwnerId);
        }
    }
}