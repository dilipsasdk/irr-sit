/**
* @author Gaurav Singh, Coforge
* @date 2023
*
* @description Test class for ShortenURL Service.
*/

@IsTest
public class IRR_SVC_ShortenURLServiceTest {
      @IsTest
       Public static void testGetShortenUrl() {
         //Set up mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IRR_SVC_IShortenURLService serviceMock = (IRR_SVC_IShortenURLService) mocks.mock(IRR_SVC_ShortenURLServiceImpl.class);
        IRR_MOD_ShortenURL response  = new IRR_MOD_ShortenURL();
        List<IRR_MOD_ShortenURL.ShortURL> innerClassResList = new List<IRR_MOD_ShortenURL.ShortURL>();
    
        IRR_MOD_ShortenURL.ShortURL innerClassRes = new IRR_MOD_ShortenURL.ShortURL();
        innerClassRes.originalUrl = 'https://developer.salesforce.com';
        innerClassRes.shortenedUrl = 'test.com';
        innerClassResList.add(innerClassRes);
        
        
        response.shortenedUrls = innerClassResList;
        List<String> urls = new List<String>();
        urls.add('https://developer.salesforce.com');
        mocks.startStubbing();
        mocks.when(serviceMock.generateShortenUrl(urls))
                .thenReturn(response);
        mocks.stopStubbing();
        IRR_Application.Service.setMock(IRR_SVC_IShortenURLService.class, serviceMock);
        }

       
}