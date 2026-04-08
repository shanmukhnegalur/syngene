trigger InvoiceTrigger on Invoice__c (before insert, after insert, after update, after delete, after undelete) 
{
    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete))
    {
        InvoiceTriggerHandler.RollUpInvoiceAmount(trigger.New);
    }
    
    if(trigger.isAfter && trigger.isDelete)
    {
        InvoiceTriggerHandler.RollUpInvoiceAmount(trigger.old);
    }
    
    if(trigger.isBefore && trigger.isInsert)
    {
        InvoiceTriggerHandler.UpdateProjectInInvoice(trigger.New);
    }
    
}