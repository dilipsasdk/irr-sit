@isTest 
public class ICOUPON_AuthConnector_v2Mock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
           String fullJson = '{"access_token": "BO","token_type": "bearer","expires_in": 3599,".issued": "Thu, 09 Jun 2022 06:32:41 GMT",".expires": "Thu, 09 Jun 2022 07:32:41 GMT"}';
           HTTPResponse res = new HTTPResponse();
           res.setHeader('Content-Type', 'text/json');
           res.setBody(fullJson);
           res.setStatusCode(200);
           return res;
        
    }
}