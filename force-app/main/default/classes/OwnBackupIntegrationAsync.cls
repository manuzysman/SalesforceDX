global class OwnBackupIntegrationAsync implements Queueable, Database.AllowsCallouts {
 
    public String serviceId;
    public String stepId;
    
    public OwnBackupIntegrationAsync(String serviceIdString, String stepIdString) {
        serviceId = serviceIdString;
        stepId = stepIdString;
    }
    
    public void execute(QueueableContext context) {
        OwnBackupIntegration.checkDataBackup(serviceId, stepId);
    }
}