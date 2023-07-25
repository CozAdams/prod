/**
 * @author Andrew Yu, Nathan Vass
 * @date August/2018
 * @group Logger Factory
 * @description This class contains the logic of Email error logging strategy
 */
public with sharing class LoggerEmail extends LoggerBase implements ILogger{
    @testVisible final String ADMIN_PROFILE = 'System Administrator';
    @testVisible final Integer EMAIL_CHARACTERS_LIMIT = 30000;
    @testVisible final String JOB_NAME_PLACEHOLDER = '{!jobName}';
    @testVisible final String JOB_DESCRIPTION_PLACEHOLDER = '{!jobDescription}';
    @testVisible String emailBodyIntro;
    @testVisible String emailBody;
    @testVisible String emailSubject;
    @testVisible LogLevel emailLogLevel;
    @testVisible Integer emailBodyLength;

    private List<User> emailRecipients {
        get {
            if(emailRecipients == null) {
                emailRecipients = [SELECT Email FROM User WHERE Profile.Name =: ADMIN_PROFILE AND IsActive = true LIMIT 25];
            }
            return emailRecipients;
        }set;
    }

    public LoggerEmail(LogLevel minLogLevel,String jobname,String jobDescription) {
        this.emailLogLevel = minLogLevel;
        this.emailSubject = Label.Logger_Email_Subject
            .replace(JOB_NAME_PLACEHOLDER, jobname);
        this.emailBodyIntro = String.join(new List<String>{'Job Description : ', jobDescription + '<br/>'}, '');
        this.emailBodyLength = 0;
    }

    public override void emit() {
        if (String.isBlank(this.emailBody)) {
            return;
        }
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>(Pluck.strings(User.Id, this.emailRecipients)));
        email.setSubject(this.emailSubject);
        email.setHtmlBody(String.join(new List<String>{this.emailBodyIntro, this.emailBody}, ''));
        
        if(!test.isRunningTest()) Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
        
        this.emailBody = '';
        this.emailBodyLength = 0;
    }

    public override void log(String exceptionMessage,Type originatingClass) {
        log(exceptionMEssage, originatingClass, null);
    }

    public override void log(String exceptionMessage,Type originatingClass,Sobject record) {
        String recordInfo = '';

        if(record != null && record.Id != null) {
            recordInfo = String.join(new List<String>{
                'Go to the ',
                '<a href="' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + record.Id+ '">' + 
                    record.Id.getSobjectType().getDescribe().getLabel(),
                '</a>'
                },'');
        } else if(record != null){
            recordInfo = record + '';
        }

        String currentErrorMessage = String.join(
            new List<String>{
                'Orginating Class :' + originatingClass.getName(),
                'Exception Message :' + exceptionMessage.abbreviate(EMAIL_CHARACTERS_LIMIT),
                recordInfo
            }, '<br/>'
        );

        autoEmit(currentErrorMessage);
    }    

    @testVisible private void autoEmit(String currentErrorMessage) {
        Integer currentEmailMessageCharacterCount = currentErrorMessage.length();
        if(this.emailBodyLength + currentEmailMessageCharacterCount > EMAIL_CHARACTERS_LIMIT) {
            emit();
            this.emailBody = currentErrorMessage;
            this.emailBodyLength = currentEmailMessageCharacterCount;
        } else {
            this.emailBody += currentErrorMessage;
            this.emailBodyLength += currentEmailMessageCharacterCount;
        }
    }
}