/**
* @author Gaurav Singh, Coforge
* @date 2022
*
* @description This is the entry point for shorten url api.
*/
public class IRR_SVC_ShortenURLService {
    
    public static IRR_MOD_ShortenURL generateShortenUrl(List<String> qrCodeFormatString) {
         return service().generateShortenUrl(qrCodeFormatString);
      }

     public static IRR_SVC_IShortenURLService service() {
      return (IRR_SVC_IShortenURLService) IRR_Application.Service.newInstance(IRR_SVC_IShortenURLService.class);
  }
    public class ShortenURLServiceException extends Exception { }
}