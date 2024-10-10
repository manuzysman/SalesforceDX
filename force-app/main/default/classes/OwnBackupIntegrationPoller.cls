global class OwnBackupIntegrationPoller implements Schedulable {
	
    String serviceId;
    String stepId;
    
    global OwnBackupIntegrationPoller(String originalServiceId, String originalStepId) {
        serviceId = originalServiceId;
        stepId = originalStepId;
    }
    
    global void execute(SchedulableContext ctx) {
        System.enqueueJob(new OwnBackupIntegrationAsync(serviceId, stepId));
    }
}