@isTest
global class TestCopadoHttpCalloutMock implements HttpCalloutMock {
    
    Integer responseCode;
    String targetOrgId;
    
    public TestCopadoHttpCalloutMock(Integer code, String orgId){
        responseCode = code;
        targetOrgId = orgId;
    }
    
    global HttpResponse respond(HTTPRequest req){
      	
        HttpResponse res = new HttpResponse();
        System.debug('Endpoint: ' + req.getEndpoint());
        System.debug('targetOrgId: ' + targetOrgId);
        if (req.getEndpoint().contains('/v1/token')) {
            res.setBody('{"access_token": "732a631e23df0c4ef8df4a5e94ede366"}');
        } else if (req.getEndpoint().contains('api/v1/services/')) {
            // Get specific serviceId
            res.setBody('{"archived":0,"displayed_name":"dr@copa.do.dxprod","enabled":1,"id":26538,"last_backup":"2019-11-13 10:09:53","num_items":54368,"org_id":"' + targetOrgId + '","provider":"Salesforce Data","return_code":0,"return_message":"Unexpected error","secondary_name":"David Venegas","status":"OK","subtitle":null,"total_size":61357761}');
    	} else if (req.getEndpoint().contains('api/v1/services')) {
            // Get the full list of services
            res.setBody('[{"archived":0,"displayed_name":"dr@copa.do.dxprod","enabled":1,"id":26538,"last_backup":"2019-11-13 10:09:53","num_items":54368,"org_id":"' + targetOrgId + '","provider":"Salesforce Data","return_code":0,"return_message":"Unexpected error","secondary_name":"David Venegas","status":"OK","subtitle":null,"total_size":61357761},{"archived":0,"displayed_name":"dr@copa.do.dxprod","enabled":1,"id":26539,"last_backup":"2019-11-13 10:13:54","num_items":5913,"org_id":"00D6A000002jIzrUAE","provider":"Salesforce Metadata","return_code":0,"return_message":null,"secondary_name":"David Venegas","status":"OK","subtitle":null,"total_size":34516735},{"archived":0,"displayed_name":"dr@copado.com.ncinodeva","enabled":1,"id":26540,"last_backup":"2019-11-13 10:06:17","num_items":42549,"org_id":"00D3k000000st9XEAQ","provider":"Salesforce Data","return_code":0,"return_message":null,"secondary_name":"David Venegas","status":"OK","subtitle":null,"total_size":44541562},{"archived":0,"displayed_name":"dr@copa.do.deva","enabled":1,"id":26541,"last_backup":"2019-11-13 10:07:56","num_items":41097,"org_id":"00D58000000pVzHEAU","provider":"Salesforce Data","return_code":0,"return_message":null,"secondary_name":"David Venegas","status":"OK","subtitle":null,"total_size":44833580}]');
        } else if (req.getEndpoint().contains('/backup_now')) {
            res.setBody('{}');
        }
        else{
            system.debug('**** URL not Mocked **** ' + req.getEndpoint());
        }
        
        res.setStatus('OK');
        res.setStatusCode(responseCode);
        
        system.debug('########## ' + res.getBody());
        return res;
    }
}