/**
 * @author Anton Norell
 * @date 2019-11-23
 * @description Class used to parse a response in XML from external system C-Shark.
 * Valid scope of response is for service CSharkCustomerManagementTicketless.
 * Currently supports CustomerGet operation. The parser can be extended to support more
 * operations by adding public parsing methods for those operations. Output from parser is
 * a format that can be translated by a Salesforce Connect Custom Adapter to a SQL/SOQL response.
 */
public with sharing class CSharkResponseParser {
  /**
   * Namespaces for the C-Shark XML. Prefix is specified by _<prefix>.
   */
  public static final String XMLNS_S = 'http://schemas.xmlsoap.org/soap/envelope/';
  public static final String XMLNS_I = 'http://www.w3.org/2001/XMLSchema-instance';
  public static final String XMLNS = 'http://www.flysas.com/wcf/CSharkCustomerManagementTicketless/v1';
  public static final String XMLNS_A = 'http://www.flysas.com/wcf/CSharkCustomerManagement/v1';

  /**
   * Used to parse a response for operation CustomerGet.
   * @return List of customer rows that can be translated by Apex Customer Adapter for a SQL/SOQL result.
   */
  public static List<Map<String, Object>> parseCustomerGetResponse(
    String responseBody
  ) {
    List<Map<String, Object>> dataRows = new List<Map<String, Object>>();
    Dom.XmlNode customerGetResponse = getDocumentBody(responseBody)
      .getChildElement('CustomerGetResponse', XMLNS);
    List<Dom.XmlNode> customerGetResults = customerGetResponse.getChildElements();
    for (Dom.XmlNode customerGetResult : customerGetResults) {
      if (customerGetResult.getAttributeValue('nil', XMLNS_I) == null) {
        Map<String, Object> customerRow = parseCustomerGetResult(
          customerGetResult
        );
        dataRows.add(customerRow);
      }
    }

    return dataRows;
  }
  /**
   * Used to parse a response for operation CustomersGet.
   * @return List of customer rows that can be translated by Apex Customer Adapter for a SQL/SOQL result.
   */
  public static List<Map<String, Object>> parseCustomersGetResponse(
    String responseBody
  ) {
    List<Map<String, Object>> dataRows = new List<Map<String, Object>>();
    Dom.XmlNode customersGetResponse = getDocumentBody(responseBody)
      .getChildElement('CustomersGetResponse', XMLNS);
    Dom.XmlNode customersGetResults = customersGetResponse.getChildElement(
      'CustomersGetResult',
      xmlns
    );
    List<Dom.XmlNode> customers = customersGetResults.getchildElements();
    for (Dom.XmlNode customerGetResult : customers) {
      if (customerGetResult.getAttributeValue('nil', XMLNS_I) == null) {
        Map<String, Object> customerRow = parseCustomerGetResult(
          customerGetResult
        );
        dataRows.add(customerRow);
      }
    }
    return dataRows;
  }

  public static TPAccount parseTPAccountGetTicketlessResponse(
    String responseBody
  ) {
    Dom.XmlNode body = getDocumentBody(responseBody);
    Dom.XmlNode tpAccountResult = body
      .getChildElement('TPAccountGetTicketlessResponse', XMLNS)
      .getChildElement('TPAccountGetTicketlessResult', XMLNS);

    return new TPAccount(tpAccountResult);
  }

  /**
   * Extracts body from XML document. This method is common for all responses from C-Shark and can
   * be used to get the body for any C-Shark operation
   * @return XML node Body from document
   */
  private static Dom.XmlNode getDocumentBody(String responseBody) {
    Dom.Document document = new Dom.Document();
    document.load(responseBody);
    Dom.XmlNode rootNode = document.getRootElement();
    Dom.XmlNode body = rootNode.getChildElement('Body', XMLNS_S);
    return body;
  }

  /**
   * Used to parse a single CustomerGetResult from C-Shark and create a new customer row.
   * The method is responsible for calling other methods used to parse content of the result.
   * @param customerGetResult XML node of type CustomerGetResult to parse
   * @return A new customer row based on the content of the CustomerGetResult
   */
  @TestVisible
  private static Map<String, Object> parseCustomerGetResult(
    Dom.XmlNode customersGetResult
  ) {
    List<Dom.XmlNode> elements = customersGetResult.getChildElements();
    Map<String, Object> customerRow = new Map<String, Object>();
    for (Dom.XmlNode element : elements) {
      String elementName = element.getName();
      String elementText = element.getText();
      if (elementName == 'Identifier') {
        customerRow.put('ExternalId', elementText);
      } else if (elementName == 'EngagementList') {
        customerRow = parseEngagementList(element, customerRow);
      } else {
        customerRow.putAll(getNameValuePair(elementName, elementText));
      }
    }
    return customerRow;
  }

  /**
   * Used to iterate over engagements and parse each engagement according to rules specific for that engagement.
   * Only relevant engagements are parsed and their values added to the customer row with the field database name as key.
   * @param engagements List of engagements broken out from a CustomerGetResponse
   * @param customerRow Customer row to add values parser in list of engagements
   * @return Customer row with values from engagements added
   */
  private static Map<String, Object> parseEngagementList(
    Dom.XmlNode engagements,
    Map<String, Object> customerRow
  ) {
    for (Dom.XmlNode engagement : engagements.getChildElements()) {
      String engagementType = engagement.getAttributeValue('type', XMLNS_I);

      if (engagementType == 'EuroBonusEngagement') {
        for (Dom.XmlNode ebElement : engagement.getChildElements()) {
          customerRow.putAll(
            getNameValuePair(ebElement.getName(), ebElement.getText())
          );
        }
      } else if (engagementType == 'TravelPassEngagement') {
        for (Dom.XmlNode travelPassElement : engagement.getChildElements()) {
          customerRow.putAll(
            getNameValuePair(
              travelPassElement.getName(),
              travelPassElement.getText()
            )
          );
        }
      } else if (engagementType == 'PrivacySettings') {
        for (
          Dom.XmlNode setting : engagement.getChildElement('Settings', XMLNS_A)
            .getChildElements()
        ) {
          String settingType = setting.getChildElement('Type', XMLNS_A)
            .getText();
          customerRow.putAll(
            getNameValuePair(
              'Consent' + settingType,
              setting.getChildElement('Active', XMLNS_A).getText()
            )
          );
        }
      } else if (engagementType == 'CorporateMemberEngagement') {
        for (
          Dom.XmlNode corporateMembershipElement : engagement.getChildElements()
        ) {
          System.debug(corporateMembershipElement);
          if (
            corporateMembershipElement.getName() == 'CMPCode' &&
            (customerRow.get('CMP') == '' ||
            customerRow.get('CMP') == null)
          ) {
            customerRow.putAll(
              getNameValuePair('CMP', corporateMembershipElement.getText())
            );
          } else {
            customerRow.putAll(
              getNameValuePair(
                corporateMembershipElement.getName(),
                corporateMembershipElement.getText()
              )
            );
          }
        }
      } else if (engagementType == 'DefaultProfileEngagement') {
        Dom.XmlNode profile = engagement.getChildElement('Profile', XMLNS_A);
        for (
          Dom.XmlNode physicalAddress : profile.getChildElement(
              'PhysicalAddresses',
              XMLNS_A
            )
            .getChildElements()
        ) {
          List<Dom.XmlNode> addressFunctions = physicalAddress.getChildElement(
              'Functions',
              XMLNS_A
            )
            .getChildElements();
          String addressFunction = addressFunctions[0]
            .getChildElement('FunctionName', XMLNS_A)
            .getText();
          for (Dom.XmlNode addressNode : physicalAddress.getChildElements()) {
            customerRow.putAll(
              getNameValuePair(
                addressFunction + addressNode.getName(),
                addressNode.getText()
              )
            );
          }
        }
        for (
          Dom.XmlNode virtualAddress : profile.getChildElement(
              'VirtualAddresses',
              XMLNS_A
            )
            .getChildElements()
        ) {
          List<Dom.XmlNode> addressFunctions = virtualAddress.getChildElement(
              'Functions',
              XMLNS_A
            )
            .getChildElements();
          String addressFunction = addressFunctions[0]
            .getChildElement('FunctionName', XMLNS_A)
            .getText();
          String addressLine = virtualAddress.getChildElement(
              'VirtualAddressLine',
              XMLNS_A
            )
            .getText();
          customerRow.putAll(getNameValuePair(addressFunction, addressLine));
        }
      }
    }
    return customerRow;
  }

  /**
   * Used to generate a map from an XML element and its value. The method applies logic conversion logic to certain
   * value types, such as dates.
   * @param elementName Name of XML element
   * @param elementText Value of XML element
   * @return Map with element name as key and the value as value
   */
  public static Map<String, Object> getNameValuePair(
    String elementName,
    Object elementText
  ) {
    Map<String, Object> customerRow = new Map<String, Object>();
    if (
      elementName.endsWith('Date') &&
      elementText != null &&
      elementText != ''
    ) {
      customerRow.put(elementName, Date.valueOf(String.valueOf(elementText)));
    } else {
      customerRow.put(elementName, elementText);
    }
    return customerRow;
  }
}
