//Developer: Gavin Franklin
//Start Date 9/16/2021
@RestResource(urlMapping = '/billeriqresponse')
global class BillerDirectRTCBEndpoint {
    
    @HttpPost
    global static string  billerResponse(){
        String jsonString = RestContext.request.requestBody.toString();

        processPayload(jsonString);
        
        return 'Payload Received';
    }

    Static Case createCase(String caseType, Map<String, Object> singlePayment, Map<String, Object> InvoicePayments, Map<String, Object> results){

        System.debug('creating a case');
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Online Transactions').getRecordTypeId();
      //  Id queueId = [SELECT Id FROM Group WHERE Name = 'Online Transactions'AND Type = 'Queue'].Id;
        Id queueId = [SELECT Id FROM Group WHERE Name = 'Treasury Approver' AND Type = 'Queue'].Id;

    
        Case newCase = new Case();

        newCase.Deposit_Amount__c = Integer.valueOf(results.get('PaymentAmount'));
        newCase.Transaction_ID__c = String.valueOf( singlePayment.get('TransactionID'));
        newCase.ContactId = String.valueOf(InvoicePayments.get('BillerRemittanceField1'));
        newCase.Case_Org_PIN__c = String.valueOf(InvoicePayments.get('BillerInvoiceNo'));
        newCase.Account_Summary__c = String.valueOf(InvoicePayments.get('BillerRemittanceField2'));
        newCase.RecordTypeId = recordtypeId;
        newCase.Deposit_Amount__c = Decimal.valueOf(String.valueOf(Results.get('PaymentAmount')));
        newCase.Origin = 'MemberPortal'; //JS SE-2656 Changed Member Portal to MemberPortal
        newCase.Portal_Transaction_Type__c = 'Member Deposit';

        if(caseType == 'One-time' ){
            newCase.Contribution_Year__c = String.valueOf(InvoicePayments.get('BillerRemittanceField3')); //JS SE-2804 Populate Contribution Year for One-Time
            newCase.Status = 'Approved';
            Date dt = Date.valueOf(String.valueOf(singlePayment.get('ProcessDate')).split('T')[0]);
            // JS SE-2389 set month and day to MM/DD format
            String day = (String.valueOf(dt.day())).length() == 1 ? '0' + String.valueOf(dt.day()) : String.valueOf(dt.day());
            String month = (String.valueOf(dt.month())).length() == 1 ? '0' + String.valueOf(dt.month()) : String.valueOf(dt.month());
            newCase.Subject = String.valueOf(InvoicePayments.get('ReferenceNumber')) + '_Deposit_' + dt.year() + '-' + month + '-' + day;
            // JS SE-2389 set month and day to MM/DD format
            newCase.Contribution_Frequency__c = 'Single Sum';
            newCase.Contribution_Start_Date__c = dt;
            newCase.Most_Recent_Contribution_Date__c = dt;
            newCase.OwnerID = QueueId;
        }
        else if(caseType == 'Recurring'){
            newCase.Status = 'Approved';
            Date dt = Date.valueOf(String.valueOf(singlePayment.get('ProcessDate')).split('T')[0]);
            //Date thisMonthDate = date.newinstance(dt.year(), dt.month(), dt.day());
            
            // JS SE-2931 set month and day to MM/DD format
            String day = (String.valueOf(dt.day())).length() == 1 ? '0' + String.valueOf(dt.day()) : String.valueOf(dt.day());
            String month = (String.valueOf(dt.month())).length() == 1 ? '0' + String.valueOf(dt.month()) : String.valueOf(dt.month());
            
            Date createdDateDt = Date.valueOf(String.valueOf(singlePayment.get('CreateDate')).split('T')[0]);
            newCase.Recurring_Deposit_Received__c = createdDateDt;
            newCase.Subject = String.valueOf(InvoicePayments.get('ReferenceNumber')) + '_RecurringDeposit_' + dt.year() + '-' + month + '-' + day;
            newCase.Contribution_Frequency__c = 'Recurring';
            newCase.Most_Recent_Contribution_Date__c = dt;
            newCase.Contribution_Start_Date__c = dt;
            //JS SE-2931
        }

        return newCase;

    }

    
    public static void insertObject(Id CaseId, String transactionID, String JSONString, Boolean isSuccess, String errorMessage)
    {   
        ACH_Return_Payload1__c payload = new ACH_Return_Payload1__c();
        payload.Case__c = CaseId;
        payload.Payload__c = JSONString;
        payload.Transaction_ID__c = transactionID;
        payload.Success__c = isSuccess;
        payload.Error_Message__c = errorMessage;
        
        if(!Test.isRunningTest())
            database.insert(payload);
    }
    
    @future
    public static void processPayload(String JSONString) {
        list<Case> casesToAdd = new list<Case>();
        Case caseToUpdate;
        List<Approval.ProcessResult> lstApprovalResult = new List<Approval.ProcessResult> ();
        
        Map<String, Object> untypedJson = (Map<String, Object>)JSON.deserializeUntyped(JSONString);
        Map<String, Object> results = (Map<String, Object>)untypedJson.get('Result');
        List<Object> payments =(List<Object>)results.get('Payments');
                   
        System.debug('User ' + UserInfo.getUserId());
        System.debug('++++untypedJson is' + untypedJson);
        System.debug('++++untypedJson results is' + results);
        System.debug('++++untypedJson payment is' + payments);

        if( untypedJson.get('Success') == true){
            Map<String, Object> singlePayment = (Map<String, Object>)payments[0];
            List<Object> lstInvoicePayments =  (List<Object>)singlePayment.get('InvoicePayments');     
            Map<String, Object> InvoicePayments = (Map<String, Object>)lstInvoicePayments[0];
            String transactionID = String.valueOf(singlePayment.get('TransactionID')); //JS SE-2955 - 

            System.debug('++++untypedJson payment is' + InvoicePayments);

            if(String.valueOf(singlePayment.get('Channel')) == '4'){
                //Datetime dt = DateTime.parse(String.valueOf(singlePayment.get('ProcessDate')));
                Date thisMonthDate = Date.valueOf(String.valueOf(singlePayment.get('ProcessDate')).split('T')[0]);
                Date createdDateDt = Date.valueOf(String.valueOf(singlePayment.get('CreateDate')).split('T')[0]); //JS SE-2931 Get Created Date
                //Date thisMonthDate = date.newinstance(dt.year(), dt.month(), dt.day());
                
                // JS SE-2931 set month and day to MM/DD format
                String day = (String.valueOf(thisMonthDate.day())).length() == 1 ? '0' + String.valueOf(thisMonthDate.day()) : String.valueOf(thisMonthDate.day());
                String month = (String.valueOf(thisMonthDate.month())).length() == 1 ? '0' + String.valueOf(thisMonthDate.month()) : String.valueOf(thisMonthDate.month());
                //JS SE-2931    

                Date lastMonthDate = date.newinstance(createdDateDt.year(), createdDateDt.month() -1, createdDateDt.day());

                System.debug(lastMonthDate);
                System.debug(thisMonthDate);
                System.debug(decimal.valueOf(String.valueOf(Results.get('PaymentAmount'))));
                System.debug(String.valueOf(InvoicePayments.get('ReferenceNumber')));
                list<Case> firstCSRRecurring = [Select id, Account_Summary__r.Name, Account_Summary__r.Account_Number__c From Case Where Contribution_Frequency__c = 'Recurring' AND Contribution_Start_Date__c =: thisMonthDate AND Account_Summary__r.Account_Number__c =: String.valueOf(InvoicePayments.get('ReferenceNumber')) AND Deposit_Amount__c =: decimal.valueOf(String.valueOf(Results.get('PaymentAmount')))];
                list<Case> listRecurring = [Select id, Account_Summary__r.Name, Account_Summary__r.Account_Number__c, Origin From Case Where Contribution_Frequency__c = 'Recurring' AND Recurring_Deposit_Received__c =: lastMonthDate AND Account_Summary__r.Account_Number__c =: String.valueOf(InvoicePayments.get('ReferenceNumber')) AND Deposit_Amount__c =: decimal.valueOf(String.valueOf(Results.get('PaymentAmount')))];
                
                if(firstCSRRecurring.size() > 0){
                    system.debug('IN 1');
                    //A previous csr recurring case
                    caseToUpdate = firstCSRRecurring[0];
                    caseToUpdate.Most_Recent_Contribution_Date__c = thisMonthDate;
                    caseToUpdate.Deposit_Amount__c = decimal.valueOf(String.valueOf(Results.get('PaymentAmount')));
                    caseToUpdate.Transaction_ID__c = transactionID; //JS SE-2955 Add TransactionID
                    
                    //JS SE-2931 Set Dates
                    caseToUpdate.Subject = '' + caseToUpdate.Account_Summary__r.Account_Number__c + '_RecurringDeposit_' + thisMonthDate.year() + '-' + month + '-' + day; //JS SE-2955
                    caseToUpdate.Recurring_Deposit_Received__c = createdDateDt;
                    //JS SE-2931
                }
                else if(listRecurring.size() > 0){
                    system.debug('IN 2');
                    //a previous recurring case
                    caseToUpdate = listRecurring[0];

                    //JS SE-2955
                    //JS SE-2656 Changed Member Portal to MemberPortal
                    caseToUpdate.Subject = '' + caseToUpdate.Account_Summary__r.Account_Number__c + '_RecurringDeposit_' + thisMonthDate.year() + '-' + month + '-' + day; //JS SE-2955
                    caseToUpdate.Most_Recent_Contribution_Date__c = thisMonthDate;
                    
                    caseToUpdate.Recurring_Deposit_Received__c = createdDateDt; //JS SE-2931
                    caseToUpdate.Transaction_ID__c = transactionID; 
                    //JS SE-2955
                    
                    caseToUpdate.Deposit_Amount__c = Decimal.valueOf(String.valueOf(Results.get('PaymentAmount')));
                }
                else{
                    system.debug('IN 3');
                    //call create case type recurring
                    Case caseToAdd = createCase('Recurring',singlePayment, InvoicePayments, results);
                    casesToAdd.add(caseToAdd);
                }
            }
            else if(String.valueOf(singlePayment.get('Channel')) == '2'){
                //create new one time case
                system.debug('Channel 2');
                Case caseToAdd = createCase('One-time',singlePayment, InvoicePayments, results);
                casesToAdd.add(caseToAdd);
            }
            else if(String.valueOf(singlePayment.get('Channel')) == '6'){
                system.debug('IN 4');
                //create new csr one time case
                Date dt = Date.valueOf(String.valueOf(singlePayment.get('ProcessDate')).split('T')[0]);
                
                // JS SE-2931 set month and day to MM/DD format
                String day = (String.valueOf(dt.day())).length() == 1 ? '0' + String.valueOf(dt.day()) : String.valueOf(dt.day());
                String month = (String.valueOf(dt.month())).length() == 1 ? '0' + String.valueOf(dt.month()) : String.valueOf(dt.month());
                //JS SE-2931    
                
                String caseID = String.valueOf(InvoicePayments.get('BillerRemittanceField4')); //JS SE-2966 Change reference field to BillerRemittanceField4
                system.debug('>>>>>caseID ' + caseID);
                caseToUpdate = [Select Id, Subject From Case Where Id =: caseID][0];
                caseToUpdate.Subject = String.valueOf(InvoicePayments.get('ReferenceNumber')) + '_CSR_Deposit_' + dt.year() + '-' + month + '-' + day; //SE-2931
                caseToUpdate.Status = 'Open';
                caseToUpdate.Contribution_Frequency__c = 'Single Sum';
                caseToUpdate.Deposit_Amount__c = Decimal.valueOf(String.valueOf(Results.get('PaymentAmount')));
            }
            
            List<Database.SaveResult> srList = new List<Database.SaveResult>();
            
            if(caseToUpdate != null) {
                Database.SaveResult sr = Database.update(caseToUpdate, false);
                srList.add(sr);
            }

            if(casesToAdd != null && casesToAdd.size() > 0){
                System.debug('++++-case are' + casesToAdd);       
                srList = Database.insert(casesToAdd, false);
            }
            
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                    insertObject(sr.getId(), transactionID, jsonString, true, '');
                    
                    if(String.valueOf(singlePayment.get('Channel')) == '6') {
                        String caseID = String.valueOf(InvoicePayments.get('BillerRemittanceField4'));
                        List<Approval.ProcessSubmitRequest> lstApprovalRequest = new List<Approval.ProcessSubmitRequest>();
                        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                        req.setComments('Fifth third bank member deposite real time post back');
                        req.setObjectId(caseID);

                        req.setProcessDefinitionNameOrId('Online_Transaction_Member_Deposits2');
                        lstApprovalRequest.add(req);
                        
                        if(!Test.isRunningTest()) {
                            lstApprovalResult = Approval.process(lstApprovalRequest);                
                        }
                    }
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                        insertObject(sr.getId(), transactionID, jsonString, false, err.getMessage());
                    }
                }
            }
        }
    }

  
}