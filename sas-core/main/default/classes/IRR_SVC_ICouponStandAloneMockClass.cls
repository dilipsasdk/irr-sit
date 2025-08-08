@isTest 
public class IRR_SVC_ICouponStandAloneMockClass implements HttpCalloutMock {
     public HTTPResponse respond(HTTPRequest req) {
           String fullJson = '{"couponBatches": [{"couponBatchId": 56,"pnr": "AB12345","barcodes": ["FCdsfSARFfd34sdSDuo","FCdIbhtT53hjkSARFfd"]}]}';

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        
    }
}