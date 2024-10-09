trigger JobStepTriggerAfterUpdate on copado__JobStep__c (after update) {
    List<copado__JobStep__c> newJobSteps = new List<copado__JobStep__c>();
    Decimal minOrderDataTemplate = 0;
    Decimal maxOrderDataTemplate = 0;
    String logsManu = '';
    Boolean OwnPre = true;
    Boolean OwnPost = true;
    String pre = 'Own Data Backup Pre';
    String post = 'Own Data Backup Post';
    Integer numTemplate = 0;

    for (copado__JobStep__c originalStep : Trigger.new) {
        // The job step is a Data Template or a Data Set
        if (originalStep.copado__CustomType__c == 'Data Template - Salesforce' || originalStep.copado__CustomType__c == 'Data Set - Salesforce') {
            if (!String.isEmpty(originalStep.copado__Destination_Id__c)) {
                copado__Environment__c environment = [SELECT ID, Data_Backup_Enforcement__c 
                                                      FROM copado__Environment__c 
                                                      WHERE Id = :originalStep.copado__Destination_Id__c 
                                                      LIMIT 1];
                // Check if the environment has the Data Backup Envorcement flag set
                if (!String.isEmpty(environment.Data_Backup_Enforcement__c)) {
                    minOrderDataTemplate = originalStep.copado__Order__c;
                    maxOrderDataTemplate = originalStep.copado__Order__c;

                    List<copado__JobStep__c> jobSteps = [
                    SELECT Id, Name, copado__Order__c, copado__Status__c, copado__JobExecution__c, copado__Type__c, copado__CustomType__c
                    FROM copado__JobStep__c
                    WHERE copado__JobExecution__c = : originalStep.copado__JobExecution__c
                    ORDER BY copado__Order__c ASC
                    ];

                    if (!jobSteps.isEmpty()) {
                        System.debug('Found ' + jobSteps.size() + ' Job Steps for Job Execution: ' + originalStep.copado__JobExecution__c);
                        Boolean firstTemplate = true;
                        
                        // Loop on the job steps of the Job Execution
                        for (copado__JobStep__c step : jobSteps) {
                            if (step.copado__CustomType__c == 'Data Template - Salesforce' || step.copado__CustomType__c == 'Data Set - Salesforce') {
                                numTemplate++;
                                
                                // If it's the first Data Template or has a lower order, update minOrderDataTemplate
                                if (firstTemplate || step.copado__Order__c < minOrderDataTemplate) {
                                    minOrderDataTemplate = step.copado__Order__c;
                                    firstTemplate = false;
                                }
                                
                                // If it's the data template with the max Order
                                if (minOrderDataTemplate != 0 && step.copado__Order__c > minOrderDataTemplate) {
                                    if (maxOrderDataTemplate == null || step.copado__Order__c > maxOrderDataTemplate) {
                                        maxOrderDataTemplate = step.copado__Order__c;
                                    }
                                }
                            }
                       }
                       } else {
                           System.debug('No Job Steps found for Job Execution: ' + originalStep.copado__JobExecution__c);
                       }

                       if (originalStep.copado__Order__c >= minOrderDataTemplate && originalStep.copado__Order__c <= maxOrderDataTemplate) {
                              String flowJson = '{"flowName":"TriggerOwnbackupDataBackup2ndGen","parameters":[{"name":"Destination_Environment_ID","value":"' 
                              + environment.ID 
                              + '"},{"name":"Job_Step_ID","value":"{$context.Id}"}]}';
                 
                            // Create a Own Databackup job step before the First DataTemplate job step
                            if (environment.Data_Backup_Enforcement__c == 'Before and after deployment' || environment.Data_Backup_Enforcement__c == 'Before deployment') {
                                if (originalStep.copado__Order__c == minOrderDataTemplate) {
                                    copado__JobStep__c beforeStep = new copado__JobStep__c(
                                    copado__JobExecution__c = originalStep.copado__JobExecution__c,
                                    copado__CustomType__c = 'Flow',
                                    copado__ExecutionSequence__c = originalStep.copado__ExecutionSequence__c,
                                    copado__Order__c = minOrderDataTemplate - 1,
                                    Name = 'Own Data Backup Before Deployment',
                                    copado__Type__c = 'Flow',
                                    copado__ConfigJson__c = flowJson                      
                                    );
                                    newJobSteps.add(beforeStep);
                                }
                            } 
                            
                            // Create a Own Databackup job step after the last DataTemplate job step
                            if (environment.Data_Backup_Enforcement__c == 'Before and after deployment' || environment.Data_Backup_Enforcement__c == 'After deployment') {
                                if (originalStep.copado__Order__c == maxOrderDataTemplate) {
                                    copado__JobStep__c afterStep = new copado__JobStep__c(
                                    copado__JobExecution__c = originalStep.copado__JobExecution__c,
                                    copado__CustomType__c = 'Flow', // Replace with your desired type
                                    copado__ExecutionSequence__c = originalStep.copado__ExecutionSequence__c,
                                    copado__Order__c = maxOrderDataTemplate,
                                    Name = 'Own Data Backup After Deployment',
                                    copado__Type__c = 'Flow',
                                    copado__ConfigJson__c = flowJson                      
                                    );
                                    newJobSteps.add(afterStep);
                                }
                           }
                      }    
                   } else {
                       System.debug('  This step is outside the target range');
                   }
               }    
          }
     }
     
    // Insert new JobSteps
    if (!newJobSteps.isEmpty()) {
        insert newJobSteps;
    } 
}