@isTest 
public class IRR_SVC_ICouponMockClass implements HttpCalloutMock 
{
     public HTTPResponse respond(HTTPRequest req) {
         String fullJson = '{"couponBatchId":20}';

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        
    }
   

}