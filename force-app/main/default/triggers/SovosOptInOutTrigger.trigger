trigger SovosOptInOutTrigger on Contact (after update) {

    if(trigger.isAfter && trigger.isUpdate){
        for(Contact cnt : Trigger.new){
            Contact oldCnt = trigger.oldMap.get(cnt.Id);

            if((cnt.Opt_Out_Prompted_All_Paper_Tax_Forms__c == true && oldCnt.Opt_Out_Prompted_All_Paper_Tax_Forms__c == false)
               || (cnt.Stop_receiving_paper_tax_statements__c != oldCnt.Stop_receiving_paper_tax_statements__c)){
                SovosOptInOutController.invokeCallout(cnt.id);
            }
        }
    }
}