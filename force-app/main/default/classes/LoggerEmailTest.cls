/**
 * @author Andrew Yu, Nathan Vass
 * @date August/2018
 * @group Logger Factory
 * @description Ths test class of EmailLogger
 */

@isTest
private class LoggerEmailTest {
    static final String JOB_NAME = 'Steve Jobs';
    static final String JOB_DESCRIPTION = 'First IPhone';
    static final String EXCEPTION_MESSAGE = 'Test exception message';

    @isTest static void constructor_initializesValues() {
        String expectedSubject = Label.Logger_Email_Subject
            .replace('{!jobName}', JOB_NAME);
        Test.startTest();
            LoggerEmail logger = createLogger();
        Test.stopTest();

        System.assertEquals(expectedSubject, logger.emailSubject, 
            'Expecting the email subject to be constructed based on the Logger_Email_Subject custom label');        
        System.assert(logger.emailBodyIntro.contains(JOB_DESCRIPTION), 
            'Users should be able to see the job description in the subject of the error containing email');
    }

    private static LoggerEmail createLogger() {
        return (LoggerEmail) new LoggerFactoryDefault().createLogger(
            LoggerStrategy.EMAIL, LogLevel.ERROR, JOB_NAME, JOB_DESCRIPTION);
    }

    @isTest static void log_recordWithId_linksToRecord() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType).create().getRecord();
        LoggerEmail logger = createLogger();
        Test.startTest();
            logger.log(EXCEPTION_MESSAGE, LoggerEmail.class, testAccount);
        Test.stopTest();
        String emailBody = logger.emailBody;
        String expectedUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + testAccount.Id;

        System.assert(emailBody.contains(expectedUrl), 
            'The Email body should give users the option to click a link and view the error-causing record. Got: ' + emailBody);
        System.assert(emailBody.contains(testAccount.getSobjectType().getDescribe().getLabel()),
            'Expecting users to be able to view the type of SObject which caused the error');
        System.assert(emailBody.contains(EXCEPTION_MESSAGE),
            'Expecting the exception message to be communicated to users through the email body');
    }

    @isTest static void log_recordWithoutId_jsonDump() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType).build().getRecord();
        LoggerEmail logger = createLogger();
        Test.startTest();
            logger.log(EXCEPTION_MESSAGE, LoggerEmail.class, testAccount);
        Test.stopTest();
        String emailBody = logger.emailBody;

        System.assert(emailBody.contains(testAccount + ''), 
            'Users should be able to view a json dump of error-producing records which do not have Ids. Got: ' + emailBody);
        System.assert(emailBody.contains(EXCEPTION_MESSAGE),
            'Users should be able to view exception messages for logged errors');
    }

    @isTest static void log_nullRecord_blankInfo() {
        LoggerEmail logger = createLogger();
        Test.startTest();
            logger.log(EXCEPTION_MESSAGE, LoggerEmail.class);
        Test.stopTest();
        String emailBody = logger.emailBody;

        System.assert(emailBody.contains(EXCEPTION_MESSAGE),
            'Users should be able to view exception messages for logged errors');
    }    

    @isTest static void autoEmit_enteredErrorIsOverCharLimit_sendEmailAndStartNewMessage() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType).build().getRecord();
        LoggerEmail logger = createLogger();
        logger.emailBody = EXCEPTION_MESSAGE;
        String newMessage = 'new email body';
        logger.emailBodyLength = logger.EMAIL_CHARACTERS_LIMIT;
        Test.startTest();
            logger.autoEmit(newMessage);
            Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        String emailBody = logger.emailBody;
        System.assert(emailBody.contains(newMessage), 
            'When an email is automatically emitted because capacity is reached, any new errors that were not sent should be logged and ready for the next emit');
        System.assert(!emailBody.contains(EXCEPTION_MESSAGE), 
            'Expecting the old message to be emitted and removed from the message body when the character limit is reached');
        System.assertEquals(0, emailInvocations, 
            'An email should be send out when the character limit is reached');
    }

    @isTest static void handleErrorLogging_registersError() {
        List<Contact> willProduceError = new List<Contact>{ new Contact() };
        List<Database.SaveResult> insertErrorResult = Database.insert(willProduceError, false);
        LoggerEmail logger = createLogger();
        String expectedError = 'Test error message';
        Test.startTest();
            logger.handleErrorLogging(insertErrorResult, willProduceError, expectedError, LoggerEmailTest.class);
        Test.stopTest();

        System.assert(logger.emailBody.contains(expectedError), 
            'Expecting errors to be logged');
        System.assert(logger.emailBody.contains(LoggerEmailTest.class.getName()),
            'Expecting errors to be logged with information about the class in which the error originated');
        System.assert(logger.emailBody.contains(willProduceError[0] + ''), 
            'Expecting information about the error causing record to be logged');
    }

    @isTest static void emit() {
        LoggerEmail logger = createLogger();
        logger.emailBody = EXCEPTION_MESSAGE;
        Test.startTest();
            logger.emit();
            Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(0, logger.emailBodyLength, 
            'Expecting the length of the email body character count to be reset on send');
        System.assert(String.isBlank(logger.emailBody), 
            'Expecting the email body to be reset on send');
        System.assertEquals(0, emailInvocations, 
            'An email should be sent');
    }
}