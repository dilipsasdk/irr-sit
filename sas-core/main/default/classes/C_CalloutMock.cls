/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Generic callout mock class for use when testing integrations.
*/

@IsTest
public class C_CalloutMock implements HttpCalloutMock {

    private String body;

    private Integer statusCode;

    private String contentType;

    @TestVisible
    private HttpRequest request;

    public C_CalloutMock(String body, Integer statusCode, String contentType) {
        this.body = body;
        this.statusCode = statusCode;
        this.contentType = contentType;
    }

    public HttpResponse respond(HttpRequest req) {
        //Set request variable to allow request to be verified
        this.request = req;

        // Create a fake response
        HttpResponse res = new HttpResponse();
        if (String.isNotBlank(contentType)) res.setHeader('Content-Type', contentType);
        if (String.isNotBlank(body)) res.setBody(body);
        res.setStatusCode(statusCode);
        return res;
    }
}