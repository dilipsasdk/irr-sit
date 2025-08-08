global class ICOUPON_AuthConnector_v2 extends C_LocalAuthConnector { 
   
    /**
    * Authenticates against the service
    * @param username The client_id to use when authenticating
    * @param password The client_secret used when authenticating
    * @param param1 Authentication scope, uses default package scope if not set (optional)
    * @param param2 Account Id (optional)
    * @return The oauth access token
    */
   global override String authenticate(String username, String password, String param1, String param2){
       Http http = new Http();
       HttpRequest request = new HttpRequest();
       request.setEndpoint('callout:SAS_APIM_ICOUPON/api/token');
       request.setMethod('POST');
       Map<String, Object> bodyParams = new Map<String, Object>{
               'grant_type' => 'client_credentials',
               'client_id' => username,
               'client_secret' => password
       };

        request.setBody(
               'Client_Id=' + username +
                       '&Client_Secret=' + password +
                       '&grant_type=client_credentials');
       request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
       request.setHeader('Accept', 'application/json');

       HttpResponse res = http.send(request);
       AuthResult ar = (AuthResult)JSON.deserialize(res.getBody(), AuthResult.class);
       if(res.getStatusCode()!=200){
           throw new ICouponAuthException('Error authenticating to ICoupon: '+res.getStatusCode()+': '+ar.error);
       }
       return ar.access_token;
   }

   /**
       JSON structure for the authentication result
   */
   private class AuthResult{
       String access_token;
       String token_type;
       String error;
       Integer  expires_in;
       Datetime issued;
       DateTime expires;
   }

   /**
    * Custom exception class for ICoupon auth exceptions
    */
   public class ICouponAuthException extends Exception{}
}