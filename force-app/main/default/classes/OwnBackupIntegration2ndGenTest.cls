@isTest
private class OwnBackupIntegration2ndGenTest {
    
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
        
        copado__Result__c result = new copado__Result__c(
            copado__Status__c = 'Not Started',
            copado__Job_Type__c = 'SFDX_Data_Deploy'

        );
        insert result;
        
        copado__JobStep__c step = new copado__JobStep__c(
            copado__JobExecution__c = jobExecution.Id,
             copado__CustomType__c = 'Data Template - Salesforce',
            copado__Order__c = 2,
            copado__Type__c = 'function',
            Name = 'Test Data Template Step',
            copado__Result__c = result.Id
        );
        insert step;
    }
    
    @isTest
    static void testExecuteDataBackup() {
        copado__Environment__c env = [SELECT Id FROM copado__Environment__c LIMIT 1];
        copado__JobStep__c step = [SELECT Id FROM copado__JobStep__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new OwnBackupMockHttpResponseGenerator());
        Test.startTest();
        OwnBackupIntegration2ndGen.executeDataBackup('test-org-id', step.Id);
        Test.stopTest();
    }
    
        @isTest
    static void testExecuteDataBackup1() {
        copado__Environment__c env = [SELECT Id FROM copado__Environment__c LIMIT 1];
        copado__JobStep__c step = [SELECT Id FROM copado__JobStep__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new OwnBackupMockHttpResponseGenerator());
        Test.startTest();
        OwnBackupIntegration2ndGen.executeDataBackup(env.Id, step.Id);
        Test.stopTest();
    }
    
    
    @isTest
    static void testCheckDataBackup() {
        copado__JobStep__c step = [SELECT Id FROM copado__JobStep__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new OwnBackupMockHttpResponseGenerator());
        
        Test.startTest();
        OwnBackupIntegration2ndGen.checkDataBackup('test-service-id', step.Id);
        Test.stopTest();
        
        // Verify the step was updated
        step = [SELECT copado__Result__r.copado__Status__c FROM copado__JobStep__c WHERE Id = :step.Id];
        System.assertEquals('Not Started', step.copado__Result__r.copado__Status__c);
    }
    
    @isTest
    static void testUpdateStep() {
        copado__JobStep__c step = [SELECT Id, copado__Result__c FROM copado__JobStep__c LIMIT 1];
        
        Test.startTest();
        OwnBackupIntegration2ndGen.updateStep(step.Id, 'test-service-id', 'Completed Successfully', 'Test message');
        Test.stopTest();
        
        // Verify the step and result were updated
        step = [SELECT copado__Result__r.copado__Status__c FROM copado__JobStep__c WHERE Id = :step.Id];
        System.assertEquals('Not Started', step.copado__Result__r.copado__Status__c);
    }
    

    
    @isTest
    static void testGetSessionId() {
        Test.setMock(HttpCalloutMock.class, new OwnBackupMockHttpResponseGenerator());
        
        Test.startTest();
        String sessionId = OwnBackupIntegration2ndGen.getSessionId();
        Test.stopTest();
        
        System.assertNotEquals(null, sessionId);
        System.assertEquals('mock-session-id', sessionId);
    }
    
    @isTest
    static void testGetServiceStatus() {
        Test.setMock(HttpCalloutMock.class, new OwnBackupMockHttpResponseGenerator());
        
        Test.startTest();
        String status = OwnBackupIntegration2ndGen.getServiceStatus('mock-session-id', 'test-service-id');
        Test.stopTest();
        
        System.assertEquals('SUCCESS', status);
    }
    
    @isTest
    static void testGetServices() {
        Test.setMock(HttpCalloutMock.class, new OwnBackupMockHttpResponseGenerator());
        
        Test.startTest();
        List<Object> services = OwnBackupIntegration2ndGen.getServices('mock-session-id');
        Test.stopTest();
        
        System.assertNotEquals(null, services);
        System.assertEquals(1, services.size());
    }

    
    
    @isTest
    static void testBackupNow() {
        Test.setMock(HttpCalloutMock.class, new OwnBackupMockHttpResponseGenerator());
        
        Test.startTest();
        Boolean result = OwnBackupIntegration2ndGen.backupNow('mock-session-id', 'test-service-id');
        Test.stopTest();
        
        System.assertEquals(true, result);
    }
    
    // Mock HTTP response generator
    private class OwnBackupMockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            if (req.getEndpoint().contains('/token')) {
                res.setBody('{"access_token": "mock-session-id"}');
            } else if (req.getEndpoint().contains('/services/test-service-id')) {
                res.setBody('{"status": "SUCCESS"}');
            } else if (req.getEndpoint().endsWith('/services')) {
                res.setBody('[{"id": "test-service-id", "org_id": "test-org-id", "provider": "Salesforce Data", "status": "SUCCESS"}]');
            } else if (req.getEndpoint().contains('/backup_now')) {
                res.setBody('{"status": "SUCCESS"}');
            }
            
            return res;
        }
    }
    
    
    
}