/**
 * @author Andrew Yu, Nathan Vass
 * @date August/2018
 * @group Logger Factory
 * @description This class creates error loggers. Implement any new logger by adding the strategy in 
 *  LoggerStrategy and using the interface ILogger to implement the logger functionality.
 */

public with sharing class LoggerFactoryDefault implements ILoggerFactory{
    public ILogger createLogger(LoggerStrategy strategy,LogLevel minLogLevel,String jobname,String jobDescription){
        if(strategy == LoggerStrategy.EMAIL) {
            return (ILogger) new LoggerEmail(minLogLevel, jobname, jobDescription);
        }
        return null;
    }
}