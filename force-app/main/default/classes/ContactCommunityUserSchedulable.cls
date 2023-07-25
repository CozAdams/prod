/**
 * @author Nathan Ross, Bluewolf
 *
 * @date 2018-10
 *
 * @group ContactUserCreation
 *
 * @description creates community users for eligible contacts on a delay
 */
public class ContactCommunityUserSchedulable implements Schedulable {

    public static final Integer SCOPE_SIZE = 100;

    public static IApexJobProxy apexJobProxy {
        get {
            if (apexJobProxy == null) {
                apexJobProxy = new ApexJobProxyDefault();
            }
            return apexJobProxy;
        }
        set;
    }

    public ILogger logger {
        get {
            if(logger == null) {
                logger = new LoggerFactoryDefault().createLogger(
                    LoggerStrategy.EMAIL,
                    LogLevel.ERROR,
                    'Contact User Creation Job',
                    'Creates users for eligibile community users on a delay');
            }
            return logger;
        }
        set;
    }

    public void execute(SchedulableContext sc) {
        apexJobProxy.executeBatch(
            new ContactCommunityUserBatchable(
                logger
            ),
            SCOPE_SIZE
        );
    }
}