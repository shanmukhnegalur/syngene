public class CVMS_AccountSyncQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<Account> accounts;

    public CVMS_AccountSyncQueueable(List<Account> accounts) {
        this.accounts = accounts;
    }

    public void execute(QueueableContext context) {
        CVMS_AccountSyncService.sendAccountsToCVMS(accounts);
    }
}