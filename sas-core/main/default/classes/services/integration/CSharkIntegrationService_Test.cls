/**
 * @author Anton Norell
 * @date 2019-11-25
 * @description Test class for the integration service handling requests to CShark. The CSharkResponseParser is also
 *              tested through this class.
 */
@IsTest
public with sharing class CSharkIntegrationService_Test {
  /**
   * Asserts that a search for a certain EuroBonus customer returns the correct information for that customer.
   * All expected fields should be validated against the content of the mock file in static resources.
   */
  @IsTest
  static void shouldReturnEuroBonusCustomer() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('CustomerGetResponseWithCustomer');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'text/xml');

    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    List<Map<String, Object>> response = CSharkIntegrationService.getCustomer(
      CSharkIntegrationService.SearchType.EB_NUMBER,
      '700001423'
    );
    Test.stopTest();

    System.assertEquals(
      1,
      response.size(),
      'Operation did not return the expected number of rows'
    );
    Map<String, Object> dataRow = response[0];
    System.assertEquals(
      Date.valueOf('1988-10-13T00:00:00'),
      dataRow.get('BirthDate')
    );
    System.assertEquals('Marcus', dataRow.get('FirstName'));
    System.assertEquals('M', dataRow.get('Gender'));
    System.assertEquals('10401209', dataRow.get('ExternalId'));
    System.assertEquals('CLMTestSix', dataRow.get('LastName'));
    System.assertEquals('Senior Title', dataRow.get('Title'));
    System.assertEquals('Middle', dataRow.get('MiddleName'));
    System.assertEquals('Mr', dataRow.get('Salutation'));
    System.assertEquals('Teststreet 11', dataRow.get('HomeAddressLine1'));
    System.assertEquals('', dataRow.get('HomeAddressLine2'));
    System.assertEquals('', dataRow.get('HomeAddressLine2'));
    System.assertEquals('Stockholm', dataRow.get('HomeCityName'));
    System.assertEquals('SE', dataRow.get('HomeCountryCode'));
    System.assertEquals('', dataRow.get('HomeCountyState'));
    System.assertEquals('117 30', dataRow.get('HomeZipCode'));
    System.assertEquals('false', dataRow.get('ConsentEMail'));
    System.assertEquals('true', dataRow.get('ConsentSMS'));
    System.assertEquals('false', dataRow.get('ConsentTelemarketing'));
    System.assertEquals('true', dataRow.get('ConsentEB'));
    System.assertEquals(null, dataRow.get('ConsentEB0'));
    System.assertEquals('testskapp@gmail.comm', dataRow.get('HomeE-mail'));
    System.assertEquals('+46725465098', dataRow.get('HomeMobile'));
    System.assertEquals('testskapp@gmail.com', dataRow.get('AltE-mail'));
    System.assertEquals('B', dataRow.get('IncentiveLevel'));
    System.assertEquals('11866721', dataRow.get('CompanyIdentifier'));
    System.assertEquals('RockFish', dataRow.get('CompanyName'));
    System.assertEquals('11866633', dataRow.get('ParentIdentifier'));
    System.assertEquals('928004605', dataRow.get('TravelPassAccountNumber'));
    System.assertEquals(
      Date.valueOf('2016-09-28T00:00:00'),
      dataRow.get('EnrollmentDate')
    );
    System.assertEquals('NOSECUR', dataRow.get('CMP'));
  }
  /**
   * Asserts that a search for a certain Email customer returns the correct information for that customer.
   * All expected fields should be validated against the content of the mock file in static resources.
   */
  @IsTest
  static void shouldReturnEmailCustomer() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('CustomersGetResponseWithCustomer');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'text/xml');

    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    List<Map<String, Object>> response = CSharkIntegrationService.getCustomer(
      CSharkIntegrationService.SearchType.EMAIL,
      'testskapp@gmail.comm'
    );
    Test.stopTest();

    System.assertEquals(
      1,
      response.size(),
      'Operation did not return the expected number of rows'
    );
    Map<String, Object> dataRow = response[0];
    System.assertEquals(
      Date.valueOf('1988-10-13T00:00:00'),
      dataRow.get('BirthDate')
    );
    System.assertEquals('Marcus', dataRow.get('FirstName'));
    System.assertEquals('M', dataRow.get('Gender'));
    System.assertEquals('10401209', dataRow.get('ExternalId'));
    System.assertEquals('CLMTestSix', dataRow.get('LastName'));
    System.assertEquals('Senior Title', dataRow.get('Title'));
    System.assertEquals('Middle', dataRow.get('MiddleName'));
    System.assertEquals('Mr', dataRow.get('Salutation'));
    System.assertEquals('Teststreet 11', dataRow.get('HomeAddressLine1'));
    System.assertEquals('', dataRow.get('HomeAddressLine2'));
    System.assertEquals('', dataRow.get('HomeAddressLine2'));
    System.assertEquals('Stockholm', dataRow.get('HomeCityName'));
    System.assertEquals('SE', dataRow.get('HomeCountryCode'));
    System.assertEquals('', dataRow.get('HomeCountyState'));
    System.assertEquals('117 30', dataRow.get('HomeZipCode'));
    System.assertEquals('false', dataRow.get('ConsentEMail'));
    System.assertEquals('true', dataRow.get('ConsentSMS'));
    System.assertEquals('false', dataRow.get('ConsentTelemarketing'));
    System.assertEquals('true', dataRow.get('ConsentEB'));
    System.assertEquals(null, dataRow.get('ConsentEB0'));
    System.assertEquals('testskapp@gmail.comm', dataRow.get('HomeE-mail'));
    System.assertEquals('+46725465098', dataRow.get('HomeMobile'));
    System.assertEquals('testskapp@gmail.com', dataRow.get('AltE-mail'));
    System.assertEquals('B', dataRow.get('IncentiveLevel'));
    System.assertEquals('11866721', dataRow.get('CompanyIdentifier'));
    System.assertEquals('RockFish', dataRow.get('CompanyName'));
    System.assertEquals('11866633', dataRow.get('ParentIdentifier'));
    System.assertEquals('928004605', dataRow.get('TravelPassAccountNumber'));
    System.assertEquals(
      Date.valueOf('2016-09-28T00:00:00'),
      dataRow.get('EnrollmentDate')
    );
    System.assertEquals('NOSECUR', dataRow.get('CMP'));
  }
  /**
   * Asserts that the parser can select and prioritize CMP value from different engagements.
   */
  @IsTest
  static void shouldSelectCorrectCMPCodeFromEngagements() {
    String responseWithTravelpass =
      '<?xml version="1.0"?>' +
      '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">' +
      '<s:Body>' +
      '<CustomerGetResponse xmlns="http://www.flysas.com/wcf/CSharkCustomerManagementTicketless/v1">' +
      '<CustomerGetResult xmlns:a="http://www.flysas.com/wcf/CSharkCustomerManagement/v1" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">' +
      '<a:EngagementList>' +
      '<a:Engagement i:type="a:TravelPassEngagement">' +
      '<a:CMP>NOSECUR</a:CMP>' +
      '</a:Engagement>' +
      '<a:Engagement i:type="a:CorporateMemberEngagement">' +
      '<a:CMPCode i:nil="true">RFISHSE</a:CMPCode>' +
      '</a:Engagement>' +
      '</a:EngagementList>' +
      '</CustomerGetResult>' +
      '</CustomerGetResponse>' +
      '</s:Body>' +
      '</s:Envelope>';
    String responseWithoutTravelpass =
      '<?xml version="1.0"?>' +
      '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">' +
      '<s:Body>' +
      '<CustomerGetResponse xmlns="http://www.flysas.com/wcf/CSharkCustomerManagementTicketless/v1">' +
      '<CustomerGetResult xmlns:a="http://www.flysas.com/wcf/CSharkCustomerManagement/v1" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">' +
      '<a:EngagementList>' +
      '<a:Engagement i:type="a:CorporateMemberEngagement">' +
      '<a:CMPCode i:nil="true">RFISHSE</a:CMPCode>' +
      '</a:Engagement>' +
      '</a:EngagementList>' +
      '</CustomerGetResult>' +
      '</CustomerGetResponse>' +
      '</s:Body>' +
      '</s:Envelope>';

    System.assertEquals(
      'NOSECUR',
      CSharkResponseParser.parseCustomerGetResponse(responseWithTravelpass)[0]
        .get('CMP'),
      'Selected incorrect CMP value, should have selected value for Travel Pass as it exists.'
    );
    System.assertEquals(
      'RFISHSE',
      CSharkResponseParser.parseCustomerGetResponse(
          responseWithoutTravelpass
        )[0]
        .get('CMP'),
      'Selected incorrect CMP value, should have selected value for Corporate Membership as Travel Pass is missing.'
    );
  }

  /**
   * Asserts that a negative response from the C-Shark service is handled correctly.
   */
  @IsTest
  static void shouldReturn500Error() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('CustomerGetResponseWithCustomer');
    mock.setStatusCode(500);
    mock.setHeader('Content-Type', 'text/xml');
    Test.setMock(HttpCalloutMock.class, mock);

    Exception returnedException;
    Test.startTest();
    try {
      List<Map<String, Object>> response = CSharkIntegrationService.getCustomer(
        CSharkIntegrationService.SearchType.EB_NUMBER,
        '700001423'
      );
    } catch (APIMIntegrationService.IntegrationException e) {
      returnedException = e;
    }
    Test.stopTest();

    System.assertNotEquals(
      null,
      returnedException,
      'The integration service should have thrown an exception due to a 500 error, but that did not happen.'
    );
  }

  /**
   * Asserts that when the parser for the C-Shark response fails, an exception is thrown.
   */
  @IsTest
  static void shouldReturnParseError() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('CustomerGetResponseParseError');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'text/xml');

    Test.setMock(HttpCalloutMock.class, mock);

    Exception returnedException;
    Test.startTest();
    try {
      List<Map<String, Object>> response = CSharkIntegrationService.getCustomer(
        CSharkIntegrationService.SearchType.EB_NUMBER,
        '700001423'
      );
    } catch (Exception e) {
      returnedException = e;
    }
    Test.stopTest();

    System.assertNotEquals(null, returnedException);
  }

  @IsTest
  static void shouldReturnTPAccountDetails() {
    Test.setMock(HttpCalloutMock.class, new APIMMock());

    Test.startTest();
    TPAccount parsedTPAccount = CSharkIntegrationService.getTPAccount(
      '927229609'
    );
    Test.stopTest();

    TPAccount.Product tpcProduct;

    for (TPAccount.Product product : parsedTPAccount.products) {
      if (product.typeCode == 'TPC') {
        tpcProduct = product;
      }
    }

    System.assertEquals(
      '544300056',
      parsedTPAccount.euroBonusNumber,
      'Account data should be parsed correctly.'
    );
    System.assertEquals(
      'Travel Pass Corporate',
      tpcProduct.typeName,
      'Products should be parsed correctly.'
    );
  }

  /**
   * Asserts that the the CustomerGet body generation method uses the correct search engagement type value
   * bases on tha classes' search type enum list. If this method fails, check the order of the enums
   * for SearchType in CSharkIntegrationService.
   */
  @IsTest
  static void shouldGenerateSOAPDocumentCorrectly() {
    DOM.Document generatedBody = CSharkIntegrationService.constructSoapRequestBody(
      CSharkIntegrationService.OperationName.CustomerGet,
      new Map<String, String>{
        'searchEngagementType' => 'EuroBonus',
        'engagementSearchKey' => '01234567890'
      }
    );

    String expectedXML =
      '<?xml version="1.0" encoding="UTF-8"?>' +
      '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">' +
      '<Body>' +
      '<CustomerGet xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.flysas.com/wcf/CSharkCustomerManagementTicketless/v1">' +
      '<searchEngagementType>EuroBonus</searchEngagementType>' +
      '<engagementSearchKey>01234567890</engagementSearchKey>' +
      '</CustomerGet>' +
      '</Body>' +
      '</Envelope>';

    System.assertEquals(
      expectedXML.trim(),
      generatedBody.toXmlString().trim(),
      'Generated XML should match template.'
    );
  }
}
