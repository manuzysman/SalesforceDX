public class OwnBackupIntegration2ndGen {
    
    public static String ownBackupStepName = 'OwnBackup - Data Backup';
    public static String taskDescription = 'This step automatically triggers an OwnBackup job for the target Org.\\r\\n\\r\\ntThis step is automatically updated when the data backup job completes.\\r\\n\\r\\nYou can open the OwnBackup account to check the detailed results of this job.';
    public static Integer pollerMinuteInterval = 2;

    // OwnBackup and Copado statuses
    public static List<String> validDataProviders = new List<String>{'Salesforce Data', 'Salesforce Sandbox Data'}; 
    public static List<String> invalidStatuses = new List<String>{'ARCHIVED', 'TO_DELETE', 'FAILED', 'WARNING', 'ERROR'};
    public static String backupInProgressStatus = 'INPROGRESS';
    public static String stepSuccess = 'Completed Successfully';
    public static String stepFailed = 'Completed with Errors';
    
    @InvocableMethod(label='Execute OwnBackup Data Backup' description='Triggers an OwnBackup job for the target Org')
    public static List<String> invocableExecuteDataBackup(List<BackupRequest> requests) {
        List<String> results = new List<String>();
        
        for (BackupRequest request : requests) {
            // Start the data backup process
            executeDataBackup(request.environmentId, request.stepId);
            results.add('Data backup process initiated for Environment ID: ' + request.environmentId);
        }
        
        return results;
    }
    
    // Wrapper class to hold the input parameters for the invocable method
    public class BackupRequest {
        @InvocableVariable(required=true label='Environment ID' description='The ID of the Environment to backup')
        public String environmentId;
        
        @InvocableVariable(required=true label='Step ID' description='The ID of the Step record')
        public String stepId;
    }
    
    // Modify the executeDataBackup method to be public
    public static void executeDataBackup(String targetOrgId, Id stepId) {
         String sessionId = getSessionId();
        if (sessionId != null) {
            List<Object> services = getServices(sessionId);
            
            if (services != null) {
                // Deserialize the JSON string into collections of primitive data types.
                // Loop through the services
                String serviceId = '';
                String serviceStatus = '';
                for (Object service: services) {
                    String serviceSerializedString = JSON.serialize(service);
                    Map<String, Object> serviceMap = (Map<String, Object>) JSON.deserializeUntyped(serviceSerializedString);
                    
                    // Check if this service is linked to the target Org Id and is of type Data
                    String orgId = String.valueOf(serviceMap.get('org_id'));
                    String provider = String.valueOf(serviceMap.get('provider'));
                    System.debug('targetOrgId: ' + targetOrgId);
                    System.debug('orgId: ' + orgId);
                    System.debug('validDataProviders: ' + validDataProviders);
                    System.debug('provider: ' + provider);
                    if (targetOrgId == orgId && (validDataProviders.contains(provider))) {
                        
                        // Check if this service is available. Otherwise keep looking for another available service.
                        if (!invalidStatuses.contains(serviceStatus)) {
                            serviceId = String.valueOf(serviceMap.get('id'));
                            serviceStatus = String.valueOf(serviceMap.get('status'));
                            System.debug('Matched a data service for the target Org, serviceId: ' + serviceId + ', serviceStatus: '+serviceStatus);
                            break;
                        } else {
                            System.debug('Matched a data service for the target Org, but this service is not available: ' + serviceId + ', serviceStatus: '+serviceStatus);
                        }
                    } else {
                        System.debug('This is not the targetOrgId or it is not a Data or Sandbox Data Provider');
                    }
                }
                
                // Check if the backup service is already in progress
                if (String.isEmpty(serviceId)) {
                    System.debug('No data backup service found for this Org');
                    updateStep(stepId, '-', stepFailed, 'There is no data backup service available for the target Org: ' + targetOrgId + '.\\r\\nOpen the OwnBackup account and create a data backup service for the target Org and then restart this deployment.');
                } else if (serviceStatus == backupInProgressStatus) {
                    System.debug('The service is in progress');
                    // TODO: Determine if this is a full backup or a manual backup 
                    
                    // Schedule the next poller in a few minutes from now
                    OwnBackupIntegration2ndGen.scheduleIntegrationPoller(serviceId, stepId, pollerMinuteInterval);
                } else {
                    System.debug('The service status is not in progress: '+serviceStatus);
                    
                    if (backupNow(sessionId, serviceId)) {
                        System.debug('The request to start a backup service succeeded.');
                        // Schedule the next poller in 2 minutes from now to check the status of the backup job
                        OwnBackupIntegration2ndGen.scheduleIntegrationPoller(serviceId, stepId, pollerMinuteInterval);
                        
                    
                    } else {
                        System.debug('The request to start a backup service failed.');
                        updateStep(stepId, serviceId, stepFailed, 'The request to start a backup service failed.');
                        
                    }
                } 
            } else {
                System.debug('Getting the service details failed.');
                updateStep(stepId, '-', stepFailed, 'The request to OwnBackup to get the service details failed.');
            }
            
        } else {
            System.debug('The OwnBackup authentication request failed.');
            OwnBackupIntegration2ndGen.updateStep(stepId, '-', stepFailed, 'Could not authenticate the OwnBackup account with the given credentials.');
        }
    }
    public static void checkDataBackup(String serviceId, Id stepId) {
        System.debug('serviceId: ' + serviceId + ', stepId: '+stepId);           
        // Execute the OwnBackup Job
        String sessionId = getSessionId();
        if (sessionId != null) {
            
            // Get the list of services
            String serviceStatus = getServiceStatus(sessionId, serviceId);
            if (serviceStatus != null) {
                System.debug('Successfully received the service status: ' + serviceStatus);
                // Check if the backup service is already in progress
                if (serviceStatus == OwnBackupIntegration2ndGen.backupInProgressStatus) {
                    System.debug('The data backup service is still in progress');
                    // Schedule the next poller in a few minutes from now
                    OwnBackupIntegration2ndGen.scheduleIntegrationPoller(serviceId, stepId, OwnBackupIntegration.pollerMinuteInterval);
                
                } else if (!OwnBackupIntegration2ndGen.invalidStatuses.contains(serviceStatus)) {
                    System.debug('The backup service completed. Current status: '+serviceStatus);
                    OwnBackupIntegration2ndGen.updateStep(stepId, serviceId, OwnBackupIntegration2ndGen.stepSuccess, OwnBackupIntegration2ndGen.taskDescription + '\\r\\n\\r\\Service id: ' + serviceId);
                
                } else {
                    System.debug('The backup service status is failed, update the step as failed.');
                    OwnBackupIntegration2ndGen.updateStep(stepId, serviceId, OwnBackupIntegration2ndGen.stepFailed, 'The backup service is not available. The backup service status is: '+serviceStatus);
                }
            } else {
                System.debug('Getting the backup service details failed. ');
                OwnBackupIntegration2ndGen.updateStep(stepId, serviceId, OwnBackupIntegration2ndGen.stepFailed, 'The request to OwnBackup to get the service details failed.');
            }
            
        } else {
            System.debug('The OwnBackup authentication request failed. ');
            OwnBackupIntegration2ndGen.updateStep(stepId, serviceId, OwnBackupIntegration2ndGen.stepFailed, 'Could not authenticate the OwnBackup account with the given credentials.');
        } 
    }
    
    public static void scheduleIntegrationPoller(String serviceId, String stepId, Double minutes) {
        Datetime dt = Datetime.now() + (minutes/(24*60)); // e.g. 2 mins = (2*60)/(24*60*60)
        String timeForScheduler = dt.format('s m H d M \'?\' yyyy');                    
        System.schedule('OwnBackupPoller_'+timeForScheduler, timeForScheduler, new OwnBackupIntegrationPoller(serviceId, stepId));
    }
    
    public static void updateStep(String stepId, String serviceId, String status, String message) {        
        if (status == 'Completed with Errors' || status == 'Completed Successfully') {   
            System.debug('Update step with id: '+stepId);            
      
            copado__JobStep__c step = [Select Id, Name, copado__Result__c FROM copado__JobStep__c WHERE Id = :stepId];
                        System.debug('222');
            System.debug('Result' + step.copado__Result__c);

            copado__Result__c result = [Select Id, Name, copado__Status__c FROM copado__Result__c WHERE Id = :step.copado__Result__c];
            if (status == 'Completed with Errors') {
                result.copado__Status__c = 'Failed';
                List<copado__event__e> inkEvents = new List<copado__event__e>();
                inkEvents.add(new copado__event__e( copado__Payload__c = '{"errorMessage" : "Error during the Execution of Ownbackup' + message +'", "isSuccess" : false}',
                copado__Topic_Uri__c = '/events/copado/v1/step-result/' + result.Id ));
                // Call method to publish events
                List<Database.SaveResult> results = EventBus.publish(inkEvents);

                // Inspect publishing result for each event
                for (Database.SaveResult sr : results) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully published event.');
                    } else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Error returned: ' +
                            err.getStatusCode() +
                            ' - ' +
                            err.getMessage());
                    }
                }       
            }

            } else if (status == 'Completed Successfully') {
                result.copado__Status__c = 'Success';
                List<copado__event__e> inkEvents = new List<copado__event__e>();
                inkEvents.add(new copado__event__e( copado__Payload__c = '{            "isSuccess": true        }',
                copado__Topic_Uri__c = '/events/copado/v1/step-result/' + result.Id ));
                
                // Call method to publish events
                List<Database.SaveResult> results = EventBus.publish(inkEvents);
                
                // Inspect publishing result for each event
                for (Database.SaveResult sr : results) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully published event.');
                    } else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Error returned: ' +
                            err.getStatusCode() +
                            ' - ' +
                            err.getMessage());
                          }
                   }       
                }
            }
            if (!Test.isRunningTest()) {
                update result;
            
                if (!String.isEmpty(message)) {
                    System.debug('Attach the message: '+message);
                    Attachment attachment = new Attachment(Name = String.valueOf(step.copado__Result__c), ParentId = stepId, Body = Blob.valueOf(message));
                    insert attachment;
                }
            }
        }
    }

    public static String getSessionId(){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Ownbackup_Auth/oauth2/aus4c3z3l8FqrbqDU4h7/v1/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Accept', 'application/json');
        String body = 'client_id=0oa4c413eq8wwcEzP4h7&refresh_token={!$Credential.Password}&grant_type=refresh_token&scope=api:access';
        req.setBody(body);
        System.debug('check: '+body);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('info: '+res);
        System.debug('info: '+res.getBody());
    
        if (res.getStatusCode() == 200) {
            // Deserialize the JSON string into collections of primitive data types.
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            // Get the sessionId from the results
            String sessionId = (String) results.get('access_token');  
            return sessionId;
        }else{
            System.debug('Error: '+res);
            System.debug('Error: '+res.getBody());
        }
        return null; 
    }

    public static String getServiceStatus(String sessionId, String serviceId){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Ownbackup/api/v1/services/'+ serviceId);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer '+sessionId);
        req.setHeader('Accept', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug(res.getBody());
        if (res.getStatusCode() == 200) {
            String resBody = '***********' + res.getBody();
            System.debug(resBody);
            Map<String, Object> serviceMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String serviceStatus = String.valueOf(serviceMap.get('status'));
            return serviceStatus;
        }
        else{
            System.debug(res.getBody());
        }
        return null;
    }

    public static List<Object> getServices(String sessionId){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Ownbackup/api/v1/services');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer '+sessionId);
        req.setHeader('Accept', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            System.debug('Successfully received the list of services:');
            // Deserialize the JSON string into collections of primitive data types.
            List<Object> services = (List<Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('Received the following services: '+services);
            return services;
        }
        else{
            System.debug(res.getBody());
        }
        return null;
    }

    public static boolean backupNow(String sessionId, String serviceId){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Ownbackup/api/v1/services/' + serviceId + '/backup_now');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer '+sessionId);
        req.setHeader('Accept', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200){
            return true;
        }
        else{
            System.debug(res.getBody());
        }
        return false;
    }
}