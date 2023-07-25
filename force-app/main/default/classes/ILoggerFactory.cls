/**
 * @author Andrew Yu, Nathan Vass
 * @date August/2018
 * @group Logger Factory
 * @description The interface of LoggerFactory. Logger factory is used to created any ILogger error logging strategy 
 */
public interface ILoggerFactory {
    /**
    * @description
    * creates a logger for the specified strategy that will
    * drop all logged messages below the minimum logged level
    * @param strategy - Specifies how errors should be logged and emitted
    * @param minLogLevel - The minimum level of errors which should be logged
    * @param jobname - A title for grouping a set of errors
    * @param jobDescription - A description for a grouping of errors
    */
    ILogger createLogger(LoggerStrategy strategy,LogLevel minLogLevel,String jobname,String jobDescription);
}