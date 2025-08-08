/**
* @author Gaurav Singh, Coforge
* @date 2023
*
* @description Concrete implementation of Sas shorten url integration functionality.
*/

public with sharing class IRR_SVC_ShortenURLServiceImpl  implements IRR_SVC_IShortenURLService{

        private static final String NAMED_CREDENTIAL = 'callout:SAS_ShortUrl_AUTH_V2';
        private static final String SHORTEN_API_URL = '/short/urls';
    
        private static C_IIntegrationExecutor integrationExecutor {
            get {
                if (integrationExecutor == null) {
                    integrationExecutor =
                            IRR_Application.IntegrationExecutorBuilder.newInstance(IRR_Application.IntegrationType.REST)
                                    .setBaseURL(NAMED_CREDENTIAL)
                                    .enableSASTracking()
                                    .build();
                }
                return integrationExecutor;
            }
            private set;
        }

    /**
     * @author Gaurav Singh, Coforge
     * @date 2023
     * 
     * @param String url 
     *
     * @return String shorten url
     */
      Public  IRR_MOD_ShortenURL generateShortenUrl(List<String> urls){
          List<Map<String, Object>> allURLS = new List<Map<String, Object>>();
          for(String url : urls){
            Map<String, Object> requestBody = new Map<String, Object>{
            'url' => url,
            'numberOfCharacters' => Integer.valueOf(System.Label.Shorten_URL_Total_Char),
            'ttl' => Integer.valueOf(System.Label.Shorten_URL_TTL)
            };
            allURLS.add(requestBody);
          }
          
           Map<String, Object> apiRequestBody = new Map<String, Object>{
            'urls' => allURLS
            };
       
            Map<String, String> setHeader = new Map<String, String>{
                'User-Agent' => 'testdsfkldsakjldksjalkfsl'
                };
             IRR_MOD_ShortenURL shortenResObj = new IRR_MOD_ShortenURL();
             
           C_IntegrationExecutorRest executor = new C_IntegrationExecutorRest(NAMED_CREDENTIAL , setHeader);
          
            C_IntegrationExecutor.IntegrationResponse responseObject = executor.executeRequest(
                SHORTEN_API_URL, C_IntegrationExecutor.Method.POST, apiRequestBody, null);
              
                if(responseObject != null && responseObject.statusCode == 200){
                    system.debug('Short URL response---> ' + responseObject.responseBody);
                    try{
                         shortenResObj = (IRR_MOD_ShortenURL)Json.deserialize(responseObject.responseBody, IRR_MOD_ShortenURL.Class);
                    }
                    catch(Exception ex){
                        shortenResObj = null;
                    }
                   
               }
               else {
                shortenResObj = null;
                system.debug('Short URL error---> ' + responseObject);
               }

          return shortenResObj;
        
    }
    
}