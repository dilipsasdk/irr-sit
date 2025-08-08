/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Updated implementation of APIM AuthConnector for use in Teds integration and future APIM integrations.
*/

global with sharing class APIM_AuthConnector_v2 extends C_LocalAuthConnector {
    /**
     * Authenticates against the service
     * @param username The username to use when authenticating
     * @param password he password used when authenticating
     * @param param1 APIM Scope
     * @param param2 (Optional) Not in use
     * @return The oauth access token
     */
    global override String authenticate(String username, String password, String param1, String param2){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:SAS_APIM_AUTH_V2');
        request.setMethod('POST');
        request.setBody(
                'Client_Id=' + username +
                        '&Client_Secret=' + password +
                        '&scope=' + param1 +
                        '&grant_type=client_credentials');
        System.debug(request.getBody());
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        HttpResponse res = http.send(request);
        AuthResult ar = (AuthResult)JSON.deserialize(res.getBody(), AuthResult.class);
        if(res.getStatusCode()!=200){
            throw new APIMAuthException('Error authenticating to APIM: '+res.getStatusCode()+': '+ar.error);
        }
        return ar.access_token;
    }

    /**
        JSON structure for the authentication result
    */
    private class AuthResult{
        String access_token;
        String error;
        String error_description;
    }

    /**
     * Custom exception class for APIM auth exceptions
     */
    public class APIMAuthException extends Exception{}
}