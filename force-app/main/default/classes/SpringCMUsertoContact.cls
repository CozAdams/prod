public class SpringCMUsertoContact {
    
        @AuraEnabled
    public static User getUser() {
         return [SELECT ContactId
                    FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }


}