@isTest 
public class IRR_SVC_ShortenMockClass implements HttpCalloutMock  {
  public HTTPResponse respond(HTTPRequest req) {
            String fullJson = '{"shortenedUrls":[{"originalUrl": "https://cloud.msg.flysas.com/qr_code?ID=M10000000000000000+00+E000000+AGPARNSK+6002+028C005A0001+000",            "shortenedUrl": "travelt.flysas.com/t/qpw-3CoV"        },        {            "originalUrl": "https://cloud.msg.flysas.com/qr_code?ID=M10000000000000000+00+E000000+AGPARNSK+6002+028C005B0002+000",            "shortenedUrl": "travelt.flysas.com/t/2cZpCwas"        },        {            "originalUrl": "https://cloud.msg.flysas.com/qr_code?ID=M10000000000000000+00+E000000+AGPARNSK+6002+028C005C0003+000", "shortenedUrl": "travelt.flysas.com/t/IEuvveLx }    ]}';
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        
    }
}