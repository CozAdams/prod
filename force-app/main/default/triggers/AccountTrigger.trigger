trigger AccountTrigger on Account (before update,before delete) {
    switch on Trigger.operationType {
         when BEFORE_UPDATE {
             for(Account acc: Trigger.new){
                 if(acc.Internal_System_Account__c==true){
                     acc.AddError('Cannot Delete or Update System Accounts.');
                 }
             }        
         }
        when BEFORE_DELETE {
            for(Account acc: Trigger.old){
                if(acc.Internal_System_Account__c==true){
                    acc.AddError('Cannot Delete or Update System Accounts.');
                }
            }
        }
        when else {
            // Do Nothing
        }
    }         
}