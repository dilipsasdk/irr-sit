/**
 * @author Niklas Lundkvist
 * @date 2020-02-28
 * @description Implementation of C:LocalAuthConnector used to authenticate to SFMC Installed Package with OAuth2.0
 */

global class SFMC_AuthConnector extends C_LocalAuthConnector {

    /**
     * Authenticates against the service
     * @param username The client_id to use when authenticating
     * @param password The client_secret used when authenticating
     * @param param1 Authentication scope, uses default package scope if not set (optional)
     * @param param2 Account Id, corresponds to BU in SFMC (optional)
     * @return The oauth access token
     */
    global override String authenticate(String username, String password, String param1, String param2){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:SAS_MC_Auth/v2/token');
        request.setMethod('POST');
        Map<String, Object> bodyParams = new Map<String, Object>{
                'grant_type' => 'client_credentials',
                'client_id' => username,
                'client_secret' => password
        };
        if (String.isNotBlank(param1)) {
            bodyParams.put('scope', param1);
        }
        if (String.isNotBlank(param2)) {
            bodyParams.put('account_id', param2);
        }
        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(bodyParams));

        HttpResponse res = http.send(request);
        AuthResult ar = (AuthResult)JSON.deserialize(res.getBody(), AuthResult.class);
        if(res.getStatusCode()!=200){
            throw new SFMCAuthException('Error authenticating to SFMC: '+res.getStatusCode()+': '+ar.error);
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
    public class SFMCAuthException extends Exception{}
}