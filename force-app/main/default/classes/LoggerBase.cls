public abstract class LoggerBase implements ILogger {

    protected String PREFIX_DELIMITER = '<br/>';

    public abstract void emit();
    public abstract void log(String exceptionMessage,Type originatingClass,Sobject record);
    public abstract void log(String exceptionMessage,Type originatingClass);
    
    public void handleErrorLogging(List<Database.SaveResult> results, List<Sobject> records, String messagePrefix, Type originatingClass) {
        for(Integer recordIndex = 0; recordIndex < records.size(); recordIndex++) {
            Database.SaveResult result = results[recordIndex];
            if(!result.isSuccess()) {
                List<String> dmlErrorMessage = new List<String>{messagePrefix};
                for(Database.Error error : result.getErrors()) {
                    dmlErrorMessage.add(error.getMessage());
                }
            
                String exceptionMessage = String.join(dmlErrorMessage, PREFIX_DELIMITER);
                log(exceptionMessage, originatingClass, records[recordIndex]);
            }
        }
    }

    public void handleErrorLogging(List<Database.UpsertResult> results, List<Sobject> records, String messagePrefix, Type originatingClass) {
        for(Integer recordIndex = 0; recordIndex < records.size(); recordIndex++) {
            Database.UpsertResult result = results[recordIndex];
            if(!result.isSuccess()) {
                List<String> dmlErrorMessage = new List<String>{messagePrefix};
                for(Database.Error error : result.getErrors()) {
                    dmlErrorMessage.add(error.getMessage());
                }
                
                String exceptionMessage = String.join(dmlErrorMessage, PREFIX_DELIMITER);
                log(exceptionMessage, originatingClass, records[recordIndex]);
            }
        }
    }
    
    public void handleErrorLogging(List<Database.DeleteResult> results, List<Sobject> records, String messagePrefix, Type originatingClass) {
        for(Integer recordIndex = 0; recordIndex < records.size(); recordIndex++) {
            Database.DeleteResult result = results[recordIndex];
            if(!result.isSuccess()) {
                List<String> dmlErrorMessage = new List<String>{messagePrefix};
                for(Database.Error error : result.getErrors()) {
                    dmlErrorMessage.add(error.getMessage());
                }
            
                String exceptionMessage = String.join(dmlErrorMessage, PREFIX_DELIMITER);
                log(exceptionMessage, originatingClass, records[recordIndex]);
            }
        }
    }
}