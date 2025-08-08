/**
 * @author Gaurav Singh
 * @date 2024-06-26
 * @description Test class for IRR_BCH_ShortPassRightUrl
 */
@IsTest
public class IRR_BCH_ShortPassRightUrlTest {
@IsTest
static void ShortPassRightUrlTest(){
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
    IRR_Shorten_Url__c obj = new IRR_Shorten_Url__c();
    obj.IRR_EU_Pass_Right_URL__c = 'https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_emailmessage.htm';
    obj.Name = 'Test';
    Insert obj;

    Test.startTest();
    Database.executeBatch(new IRR_BCH_ShortPassRightUrl());
    Test.stopTest();
}
}