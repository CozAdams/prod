/**
 * @author Andrew Yu, Nathan Vass
 * @date August/2018
 * @group Test
 * @description This is for asserting that a logger was called with the desired arguments. It does this by
 * stores any argument values in it's class body, allowing public access. 
 */

public with sharing class LoggerMock extends LoggerBase implements ILogger {
    public List<LoggedEvent> loggedEvents = new List<LoggedEvent>();
    public Boolean didEmit = false;

    class LoggedEvent {
        public String message;
        public Type originatingClass;
        public Sobject record;
    }

    public override void log(String exceptionMessage,Type originatingClass,Sobject record) {
        LoggedEvent logEvent = new LoggedEvent();
        logEvent.message = exceptionMessage;
        logEvent.originatingClass = originatingClass;
        logEvent.record = record;
        this.loggedEvents.add(logEvent);
    }

    public override void log(String exceptionMessage,Type originatingClass) {
        this.log(exceptionMessage, originatingClass, null);
    }

    public override void emit() {
        this.didEmit = true;
    }

}