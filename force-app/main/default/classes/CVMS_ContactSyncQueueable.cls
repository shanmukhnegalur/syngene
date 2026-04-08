public class CVMS_ContactSyncQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<Contact> contacts;

    public CVMS_ContactSyncQueueable(List<Contact> contacts) {
        this.contacts = contacts;
    }

    public void execute(QueueableContext context) {
        CVMS_ContactSyncService.sendContactsToCVMS(contacts);
    }
}