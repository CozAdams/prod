import { createRecord } from 'lightning/uiRecordApi';
import getSfdcSession from '@salesforce/apex/ThreatMetrixIntegrationService.getSfdcSession';
import getIntegrationDetails from '@salesforce/apex/ThreatMetrixIntegrationService.getIntegrationDetails';
import sendJsonRequest from '@salesforce/apex/ThreatMetrixIntegrationService.sendJsonRequest';

// Generate profiling tag for page
async function generateProfilingTag() {
	// Session ID for login should match SFDC, all others must be made unique
	const session = await getSfdcSession();
	let sessionId = session.SessionId + Math.floor(Date.now()/1000);

	// Build and return object with session ID and tag src string
	const queryInfo = await getIntegrationDetails({ 'actionType': 'Profiling' });
	const src = queryInfo[0].REST_Endpoint__c + 
		'org_id=' + queryInfo[0].Org_ID__c + 
		'&session_id=' + sessionId +
		'&allow_reprofile=1';

	return { sessionId, src };
}

// Build session query URL with params based on community user action type
async function buildSessionQuery(sessionId, transactionCase) {
	const actionType = transactionCase.Subject;
	const intDetails = await getIntegrationDetails({ actionType });

	if (intDetails && intDetails.length) {
		const queryInfo = intDetails[0];
		const session = await getSfdcSession();
		session.uniqueSessionId = sessionId;
		console.log('++++what is action type and session', actionType ,session  );

		let sessionQuery;
		switch (actionType) {
			case 'Login': 
				sessionQuery = new SessionQueryLogin(queryInfo, session, transactionCase);
				break;
			case 'Email_Change': 
				sessionQuery = new SessionQueryEmailChange(queryInfo, session, transactionCase);
				break;
			case 'Phone_Change': 
				sessionQuery = new SessionQueryPhoneChange(queryInfo, session, transactionCase);
				break;
			case 'Address_Change': 
				sessionQuery = new SessionQueryAddressChange(queryInfo, session, transactionCase);
				break;
			case 'Add_Bank_Account': 
				sessionQuery = new SessionQueryAddBankAccount(queryInfo, session, transactionCase);
				break;
			case 'Withdrawal': 
				sessionQuery = new SessionQueryWithdrawal(queryInfo, session, transactionCase);
				break;
		}
		
		let calloutString = queryInfo.REST_Endpoint__c;
		for (var param in sessionQuery) {
			calloutString += '&' + param + '=' + encodeURIComponent(sessionQuery[param]);
		}

		return calloutString;
	}
	else {
		return null;
	}
}

// Send session query request to ThreatMetrix and return the response
async function sendSessionQuery(calloutString) {
	let response = await sendJsonRequest({ calloutString, methodType: 'GET' });
    response = JSON.parse(response);
	return response;
}

// Insert Threat Report record built from case and response details


// Build Case record with details needed for ThreatMetrix session query request
function buildThreatReportCase(transactionCase, caseContact, subject) {
	if (transactionCase) {
		transactionCase = convertWiredObject(transactionCase);
		caseContact = convertWiredObject(caseContact);
	}
	else {
		transactionCase = { ContactId: caseContact.Id };
	}

	transactionCase.Subject = subject;
	transactionCase.Description = caseContact.PIN__c;
	transactionCase.First_Name__c = caseContact.FirstName;
	transactionCase.Middle_Name__c = caseContact.LastName;
	transactionCase.Home_Address_Street_1__c = caseContact.Home_Address_Street_1__c;
	transactionCase.Home_Address_Street_2__c = caseContact.Home_Address_Street_2__c;
	transactionCase.Home_Address_City__c = caseContact.Home_Address_City__c;
	transactionCase.Home_Address_State_Province__c = caseContact.Home_Address_State_Province__c;
	transactionCase.Home_Address_Zip__c = caseContact.Home_Address_Zip__c;
	transactionCase.Home_Address_Country__c = caseContact.Home_Address_Country__c;
	transactionCase.E_mail_Address__c = caseContact.npe01__WorkEmail__c;
	transactionCase.Email__c = caseContact.npe01__HomeEmail__c;
	transactionCase.ContactEmail = caseContact.Email;
	transactionCase.ContactPhone = caseContact.MobilePhone;

//Try adding score value to case
//	transactionCase.Score = caseContact.Score__c;

	//fields['Score__c'] = riskInfo.score;
//end try adding score value to case

	if (transactionCase.Account_Summary__r) {
		transactionCase.Account_Summary__r = convertWiredObject(transactionCase.Account_Summary__r);
	}
	
	return transactionCase;
}

// Flatten wired object for easier field value retrieval
function convertWiredObject(data) {
	return {
		Id: data.id, 
		...Object.keys(data.fields).reduce((a, f) => {
			a[f] = data.fields[f].value;
			return a;
		}, {})
	};
}

// Inner class - default session query (and login action) params
class SessionQuery {
	constructor(queryInfo, session, transactionCase) {
		this.org_id = queryInfo.Org_ID__c;
		this.api_key = queryInfo.API_Key__c;
		this.session_id = session.uniqueSessionId;
		this.web_session_id = session.SessionId;
		this.service_type = queryInfo.Service_Type__c;
		this.application_name = queryInfo.Application_Name__c;
		this.event_type = queryInfo.Event_Type__c;
        this.policy = queryInfo.Policy__c;
		this.input_ip_address = session.SourceIp;

		this.account_number = transactionCase.Description; // Contact.PIN__c
		this.account_email = transactionCase.ContactEmail;
		this.account_first_name = transactionCase.First_Name__c; // Contact.FirstName
		this.account_last_name = transactionCase.Middle_Name__c; // Contact.LastName
		this.account_telephone = transactionCase.ContactPhone; // Contact.MobilePhone
		this.account_address_street1 = transactionCase.Home_Address_Street_1__c; // Contact.Home_Address_Street_1__c
		this.account_address_street2 = transactionCase.Home_Address_Street_2__c; // Contact.Home_Address_Street_2__c
		this.account_address_city = transactionCase.Home_Address_City__c; // Contact.Home_Address_City__c
		this.account_address_state = transactionCase.Home_Address_State_Province__c; // Contact.Home_Address_State_Province__c
		this.account_address_zip = transactionCase.Home_Address_Zip__c; // Contact.Home_Address_Zip__c
		this.account_address_country = transactionCase.Home_Address_Country__c; // Contact.Home_Address_Country__c
		this.Contact_work_email = transactionCase.E_mail_Address__c; // Contact.npe01__WorkEmail__c
		this.Contact_home_email = transactionCase.Email__c; // Contact.npe01.HomeEmail__c
		this.Contact_Email = transactionCase.ContactEmail; // Contact.Email
		
		if (queryInfo.Customer_Event_Type__c) {
			this.customer_event_type = queryInfo.Customer_Event_Type__c;
		}
	}
}

// Inner class - Login session query params
class SessionQueryLogin extends SessionQuery {
	constructor(queryInfo, session, transactionCase) {
		super(queryInfo, session, transactionCase);
		this.account_login = session.Username;
	}
}

// Inner class - Email Change session query params
class SessionQueryEmailChange extends SessionQuery {
	constructor(queryInfo, session, transactionCase) {
		super(queryInfo, session, transactionCase);
		this.New_Email = transactionCase.ContactEmail;
	}
}

// Inner class - Phone Change session query params
class SessionQueryPhoneChange extends SessionQuery {
	constructor(queryInfo, session, transactionCase) {
		super(queryInfo, session, transactionCase);
		this.New_Phone = transactionCase.ContactPhone;
	}
}

// Inner class - Address Change session query params
class SessionQueryAddressChange extends SessionQuery {
	constructor(queryInfo, session, transactionCase) {
		super(queryInfo, session, transactionCase);
		this.account_address_street1 = transactionCase.Home_Address_Street_1__c;
		this.account_address_street2 = transactionCase.Home_Address_Street_2__c;
		this.account_address_city = transactionCase.Home_Address_City__c;
		this.account_address_state = transactionCase.Home_Address_State_Province__c;
		this.account_address_zip = transactionCase.Home_Address_Zip__c;
		this.account_address_country = transactionCase.Home_Address_Country__c;

		this.New_Address_Street = transactionCase.Home_Address_Street_1__c;
		this.New_Address_City = transactionCase.Home_Address_City__c;
		this.New_Address_State = transactionCase.Home_Address_State_Province__c;
		this.New_Address_Zip = transactionCase.Home_Address_Zip__c;
		this.New_Address_Country = transactionCase.Home_Address_Country__c;
	}
}

// Inner class - New Bank Account session query params
class SessionQueryAddBankAccount extends SessionQuery {
	constructor(queryInfo, session, transactionCase) {
		super(queryInfo, session, transactionCase);
		this.New_Bank_Account_Name = transactionCase.Bank_Name__c;
		this.New_Bank_account_Routing = transactionCase.Bank_Routing_ABA__c;
		this.New_Bank_Account_Number = transactionCase.Checking_Account__c;
	}
}

// Inner class - Withdrawal session query params
class SessionQueryWithdrawal extends SessionQuery {
	constructor(queryInfo, session, transactionCase) {
		super(queryInfo, session, transactionCase);
		this.transaction_amount = transactionCase.Withdrawal_Amount__c;
		this.transaction_currency = 'USD';
		this.Bank_info_Account_name = transactionCase.Bank_Name__c; // bnk_Bank__c.Name
		this.Bank_info_account_routing = transactionCase.Bank_Routing_ABA__c; // bnk_Bank__c.bnk_Routing_Number__c
		this.Bank_info_Account_Number = transactionCase.Checking_Account__c; // 'bnk_Bank__c.bnk_Account_Number__c'
		this.Withdrawal_Payment_Type = transactionCase.Distribution_Payment_Type__c;
		this.Account_summary_name = transactionCase.accountName;
		this.Account_summary_type = transactionCase.Account_Type__c; // Account_Summary__c.Account_Type__c
		this.condition_attrib_8 = 'Withdrawal Application submit';
	}
}

export {
	generateProfilingTag, 
    buildSessionQuery, 
	sendSessionQuery, 
	buildThreatReportCase, 
	convertWiredObject
}