/**
 * @author Andrew Yu, Nathan Vass
 * @date August/2018
 * @group Interface
 * @description An Logger stores and emits error information.
 */

public interface ILogger {
    /**
    * @description log a failure, optionally related to a particular 
    * record
    * @param record optional parameter for which if an sobject
    * with an id is provided, provides a link back to the record for 
    * logging strategies likee-mail.If an sobject without an id
    * is provided, it’s serialization will be dumped as part of
    * the logged message.
    * @param exceptionMessage - The desired error message
    * @param originatingClass - The class that will be displayed alongside the error
    * @param record - The error-producing record
    */
    void log(String exceptionMessage,Type originatingClass,Sobject record);

    /**
    * @description log an event that cannot be related to
    * a persisted record and for which no subject
    * is needed to be provided to investigate the event.
    * @param exceptionMessage - The desired error message
    * @param originatingClass - The class that will be displayed alongside the error
    */
    void log(String exceptionMessage,Type originatingClass);

    /**
    * @description To log error from a group of SaveResult, DeleteResult or UpsertResult.
    * @param results - a list of SaveResult, DeleteResult or UpsertResult after performing DML action
    * @param records - the original sobject records that provides the detail info about the record
    * @param defaultErrorMessage - the pre-defineoed error message that will be stored in the logger
    * @param originatingClass - The class that will be displayed alongside the error
    */
    void handleErrorLogging(List<Database.SaveResult> results, List<Sobject> records, String messagePrefix, Type originatingClass);
    void handleErrorLogging(List<Database.UpsertResult> results, List<Sobject> records, String messagePrefix, Type originatingClass);
    void handleErrorLogging(List<Database.DeleteResult> results, List<Sobject> records, String messagePrefix, Type originatingClass);
    /**
    * @description write/publish the logs as appropriate for
    * the implementing strategy if and only if there are logged 
    * lines of the provided minimum log level. Each logged message
    * successfully sent out will be removed from the logger 
    * for future calls of emit.
    */
    void emit();


}