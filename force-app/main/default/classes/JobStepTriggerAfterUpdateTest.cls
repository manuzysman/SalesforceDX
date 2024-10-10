@isTest
public class JobStepTriggerAfterUpdateTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test data
        copado__Environment__c testEnv = new copado__Environment__c(
            Data_Backup_Enforcement__c = 'Before and after deployment'
        );
        insert testEnv;
        testEnv = [SELECT Id FROM copado__Environment__c LIMIT 1];

        
        copado__JobExecution__c jobExecution = new copado__JobExecution__c(
        copado__Destination__c = testEnv.Id
        );
        insert jobExecution;
    }
    
    @isTest
    static void testDataTemplateStepCreation() {
        copado__Environment__c testEnv = [SELECT Id FROM copado__Environment__c LIMIT 1];
        copado__JobExecution__c jobExecution = [SELECT Id FROM copado__JobExecution__c LIMIT 1];
        
        Test.startTest();
        
        copado__JobStep__c dataTemplateStep = new copado__JobStep__c(
            copado__JobExecution__c = jobExecution.Id,
            copado__CustomType__c = 'Data Template - Salesforce',
            copado__Order__c = 2,
            copado__Type__c = 'function',
            Name = 'Test Data Template Step'
            
        );
        insert dataTemplateStep;
        
        update dataTemplateStep;
        
        Test.stopTest();
        
        // Verify results
        List<copado__JobStep__c> createdSteps = [SELECT Id, Name, copado__Order__c FROM copado__JobStep__c WHERE copado__JobExecution__c = :jobExecution.Id ORDER BY copado__Order__c];
        
        System.assertEquals(3, createdSteps.size(), 'Expected 3 job steps (1 original + 2 backups)');
        System.assertEquals('Own Data Backup Before Deployment', createdSteps[0].Name, 'First step should be before backup');
        System.assertEquals(1, createdSteps[0].copado__Order__c, 'Before backup step should have order 1');
        System.assertEquals('Test Data Template Step', createdSteps[1].Name, 'Second step should be the original data template step');
        System.assertEquals('Own Data Backup After Deployment', createdSteps[2].Name, 'Third step should be after backup');
        System.assertEquals(2, createdSteps[2].copado__Order__c, 'After backup step should have order 2');
    }
    
    @isTest
    static void testDataSetStepCreation() {
        copado__Environment__c testEnv = [SELECT Id FROM copado__Environment__c LIMIT 1];
        copado__JobExecution__c jobExecution = [SELECT Id FROM copado__JobExecution__c LIMIT 1];
        
        Test.startTest();
        
        copado__JobStep__c dataSetStep = new copado__JobStep__c(
            copado__JobExecution__c = jobExecution.Id,
            copado__CustomType__c = 'Data Set - Salesforce',
            copado__Order__c = 2,
            copado__Type__c = 'function',
            Name = 'Test Data Set Step'
        );
        insert dataSetStep;
        
        update dataSetStep;
        
        Test.stopTest();
        
        // Verify results
        List<copado__JobStep__c> createdSteps = [SELECT Id, Name, copado__Order__c FROM copado__JobStep__c WHERE copado__JobExecution__c = :jobExecution.Id ORDER BY copado__Order__c];
        
        System.assertEquals(3, createdSteps.size(), 'Expected 3 job steps (1 original + 2 backups)');
        System.assertEquals('Own Data Backup Before Deployment', createdSteps[0].Name, 'First step should be before backup');
        System.assertEquals('Test Data Set Step', createdSteps[1].Name, 'Second step should be the original data set step');
        System.assertEquals('Own Data Backup After Deployment', createdSteps[2].Name, 'Third step should be after backup');
    }
    
    @isTest
    static void testNoBackupCreation() {
        copado__Environment__c testEnv = [SELECT Id FROM copado__Environment__c LIMIT 1];
        copado__JobExecution__c jobExecution = [SELECT Id FROM copado__JobExecution__c LIMIT 1];
        
        testEnv.Data_Backup_Enforcement__c = null;
        update testEnv;
        
        Test.startTest();
        
        copado__JobStep__c dataTemplateStep = new copado__JobStep__c(
            copado__JobExecution__c = jobExecution.Id,
            copado__CustomType__c = 'Data Template - Salesforce',
            copado__Order__c = 2,
            copado__Type__c = 'function',
            Name = 'Test Data Template Step'
        );
        insert dataTemplateStep;
        
        update dataTemplateStep;
        
        Test.stopTest();
        
        // Verify results
        List<copado__JobStep__c> createdSteps = [SELECT Id, Name FROM copado__JobStep__c WHERE copado__JobExecution__c = :jobExecution.Id];
        
        System.assertEquals(1, createdSteps.size(), 'Expected only 1 job step (no backups)');
        System.assertEquals('Test Data Template Step', createdSteps[0].Name, 'Only step should be the original data template step');
    }
    
    @isTest
    static void testMultipleDataTemplateSteps() {
        copado__Environment__c testEnv = [SELECT Id FROM copado__Environment__c LIMIT 1];
        copado__JobExecution__c jobExecution = [SELECT Id FROM copado__JobExecution__c LIMIT 1];
        
        List<copado__JobStep__c> stepsToInsert = new List<copado__JobStep__c>();
        for(Integer i = 1; i <= 3; i++) {
            stepsToInsert.add(new copado__JobStep__c(
                copado__JobExecution__c = jobExecution.Id,
                copado__CustomType__c = 'Data Template - Salesforce',
                copado__Order__c = i,
            copado__Type__c = 'function',
                Name = 'Test Data Template Step ' + i
            ));
        }
        insert stepsToInsert;
        
        Test.startTest();
        
        for(copado__JobStep__c step : stepsToInsert) {
        }
        update stepsToInsert;
        
        Test.stopTest();
        
        // Verify results
        List<copado__JobStep__c> createdSteps = [SELECT Id, Name, copado__Order__c FROM copado__JobStep__c WHERE copado__JobExecution__c = :jobExecution.Id ORDER BY copado__Order__c];
        
        System.assertEquals(5, createdSteps.size(), 'Expected 5 job steps (3 original + 2 backups)');
        System.assertEquals('Own Data Backup Before Deployment', createdSteps[0].Name, 'First step should be before backup');
        System.assertEquals(0, createdSteps[0].copado__Order__c, 'Before backup step should have order 0');
        System.assertEquals('Own Data Backup After Deployment', createdSteps[4].Name, 'Last step should be after backup');
        System.assertEquals(3, createdSteps[4].copado__Order__c, 'After backup step should have order 3');
    }
}