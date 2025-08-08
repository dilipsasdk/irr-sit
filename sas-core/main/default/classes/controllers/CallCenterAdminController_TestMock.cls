@isTest
global class CallCenterAdminController_TestMock implements HttpCalloutMock{
    global HttpResponse respond(HTTPRequest req){
        HttpResponse res = new HttpResponse();
        res.setStatus('OK');
        res.setStatusCode(200);
        res.setBody('[{"userId": "1d4603f5-76b5-45ea-b04f-69056a5c060c", "success": true}, {"userId": "fake", "success": false}]');
        return res;
    }
}