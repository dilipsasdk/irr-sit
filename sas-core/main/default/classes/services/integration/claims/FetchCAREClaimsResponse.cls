/**
 * Response class for CARE claims query from EDW.
 *
 * The response structure is inconsistent and requires custom parsing logic.
 *
 * All of the List elements in the original response can be either JSON arrays,
 * or JSON objects. If there is only a single entry in the list, they are
 * returned as an object, if there are more, they are returned as an array.
 */
public class FetchCAREClaimsResponse {
  public String status { get; set; }
  public Response response { get; set; }

  public class Response {
    public List<Cases> cases { get; set; }
  }

  public class Cases {
    public Datetime dateCreated { get; set; }
    public Datetime flightDate { get; set; }
    public String pnr { get; set; }
    public String caseId { get; set; }
    public String customerId { get; set; }
    public String pir { get; set; }
    public Datetime lastModified { get; set; }
    public Datetime dateClosed { get; set; }
    public String flightNumber { get; set; }

    public List<Settlements> settlements { get; set; }
    public List<Notes> notes { get; set; }
    public List<Decisions> decisions { get; set; }
    public List<Pnrs> pnrs { get; set; }
    public List<Customers> customers { get; set; }
    public List<Categories> categories { get; set; }

    public Cases() {
      notes = new List<Notes>();
      decisions = new List<Decisions>();
      pnrs = new List<Pnrs>();
      customers = new List<Customers>();
      categories = new List<Categories>();
      settlements = new List<Settlements>();
    }
  }

  public class Settlements {
    public Decimal amount { get; set; }
    public Decimal amountInSEK { get; set; }
    public String dateSentToAmadeus { get; set; }
    public String clmTransactionId { get; set; }
    public String type { get; set; }
    public String controlState { get; set; }
    public String csCategory { get; set; }
    public String clmState { get; set; }
    public String bankDetails { get; set; }
    public String dateLastModified { get; set; }
    public String dateCreated { get; set; }
    public String dateApproved { get; set; }
    public String caseId { get; set; }
    public String catName { get; set; }
    public String customerId { get; set; }
    public String additionalInfo { get; set; }
    public String settlementCurrency { get; set; }
    public String sEBState { get; set; }
    public List<SettlementItems> settlementItems { get; set; }

    public Settlements() {
      settlementItems = new List<SettlementItems>();
    }
  }

  public class SettlementItems {
    public Integer stiEurobonusPoints { get; set; }
    public String stiVoucherSubtype { get; set; }
    public Decimal stiAmount { get; set; }
    public String stiCusId { get; set; }
    public String stiComments { get; set; }
    public String stiCostAcc { get; set; }
  }
  public class Notes {
    public Integer noteSeq { get; set; }
    public String caseId { get; set; }
    public String customerId { get; set; }
    public String noteValue { get; set; }
  }
  public class Decisions {
    public String dicCode { get; set; }
    public String dczId { get; set; }
    public String caseId { get; set; }
    public String customerId { get; set; }
    public String dicName { get; set; }
    public String dicType { get; set; }
  }
  public class Pnrs {
    public String pnrId { get; set; }
    public String pnr { get; set; }
    public String caseId { get; set; }
  }
  public class Customers {
    public String cusPirId { get; set; }
    public String caseId { get; set; }
    public String customerId { get; set; }
    public String cusFirstname { get; set; }
    public String cusLastname { get; set; }
    public String cusPnrId { get; set; }
  }
  public class Categories {
    public String catId { get; set; }
    public String caseId { get; set; }
    public String customerId { get; set; }
    public String CatName { get; set; }
  }

  /**
   * Parses the CARE Claims detail response from EDW.
   */
  public static FetchCAREClaimsResponse parse(String jsonStr) {
    /**
     * The response from EDW is unfortunately a bit weird so we need to
     * manually parse the response, instead of relying to standard Salesforce
     * parsing.
     *
     * See the APIM mock responses for a full example of the schema.
     *
     * At a high level the response structure follows the structure the
     * FetchCAREClaimsResponse class lays out. However, we have an issue with
     * the list entries. If any of those keys in the response contains only
     * element in the value, we will receive that object as the value of that
     * key, instead of the array with a single element.
     *
     * Another issue is that most of the lists contain an extra level, except
     * for settlement items. So, e.g. for customers, the data looks like this (for
     * a single case).
     *
     * If there is a single customer:
     * ```
     * {
     * ... // other fields for case
     * customers: {
     *   customer: {
     *     ...customerData
     *   }
     * }
     * ...
     * }```
     *
     * or if there are several customers:
     * ```
     * {
     * ... // other fields for case
     * customers: {
     *   customer: [
     *    {
     *     ...customerData1
     *    },
     *    {
     *     ...customerData2
     *    }
     *   ]
     * }
     * ...
     * }```
     */
    FetchCAREClaimsResponse toReturn = new FetchCAREClaimsResponse();

    // The response has one field named currency which is a reserved name in
    // Apex. The simplest solution for this one case is just to do this.
    String jsonStrWithoutReservedWords = jsonStr.replace(
      '"currency":',
      '"settlementCurrency":'
    );

    JSONParser parser = JSON.createParser(jsonStrWithoutReservedWords);

    while (parser.nextToken() != null) {
      switch on parser.getCurrentToken() {
        when FIELD_NAME {
          switch on parser.getCurrentName() {
            when 'status' {
              parser.nextToken();
              toReturn.status = parser.getText();
              // We're currently always expecting status == 'SUCCESS'
              // TODO: Should probably add some failure handling logic also here.
            }
            when 'response' {
              toReturn.response = new Response();
              // toReturn.response.cases = new List<Cases>();

              toReturn.response.cases = parseCases(parser);
            }
          }
        }
      }
    }
    return toReturn;
  }

  /**
   * Parses the given json string into a list of objects of the given type.
   *
   * @param parser JSONParser of which contents should be parsed into the object list.
   * @param apexType Type to which the JSON should be parsed into.
   */
  private static List<Object> parseToList(
    JSONParser parser,
    System.Type apexType
  ) {
    List<Object> toReturn = new List<Object>();

    parser.nextToken(); // Skip START_OBJECT or jump to empty string
    if (parser.getCurrentToken() == JSONToken.VALUE_STRING) {
      // If there are no values for a potential array, we get an empty string.
      parser.nextToken();
      return toReturn;
    }
    parser.nextToken(); // Skip mid-level name. Format is always {"customers": {"customer": {} | []}}
    JSONToken currentToken = parser.nextToken(); // Land on START_OBJECT or START_ARRAY

    switch on currentToken {
      when START_ARRAY {
        while (currentToken != JSONToken.END_ARRAY) {
          if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
            toReturn.add(parser.readValueAs(apexType));
            parser.skipChildren();
          }
          currentToken = parser.nextToken();
        }
      }
      when START_OBJECT {
        toReturn.add(parser.readValueAs(apexType));
        parser.skipChildren();
      }
    }
    parser.nextToken(); // Skip END_ARRAY or END_OBJECT
    parser.nextToken(); // Skip top level END_OBJECT

    return toReturn;
  }

  private static List<Cases> parseCases(JSONParser parser) {
    List<Cases> parsedCases = new List<Cases>();

    parser.nextToken(); // Skip START_OBJECT
    parser.nextToken(); // Skip FIELD_NAME: "cases"
    parser.nextToken(); // Skip START_OBJECT
    parser.nextToken(); // Skip FIELD_NAME: "case"
    JSONToken currentToken = parser.nextToken(); // Land on START_OBJECT or START_ARRAY
    switch on currentToken {
      when START_OBJECT {
        parsedCases.add(parseSingleCase(parser));
      }
      when START_ARRAY {
        while (currentToken != JSONToken.END_ARRAY && currentToken != null) {
          if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
            parsedCases.add(parseSingleCase(parser));
          } else {
            currentToken = parser.nextToken();
          }
        }
      }
    }

    return parsedCases;
  }

  private static Cases parseSingleCase(JSONParser parser) {
    Cases parsedCase = new Cases();
    parser.nextToken();
    // Loop until we find the matching paren for the case object's opening paren
    while (parser.getCurrentToken() != JSONToken.END_OBJECT) {
      if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
        switch on parser.getCurrentName() {
          when 'dateCreated' {
            parser.nextValue();
            parsedCase.dateCreated = DateUtils.isValidIsoDatetime(
                parser.getText()
              )
              ? parser.getDatetimeValue()
              : null;
            parser.nextToken();
          }
          when 'flightDate' {
            parser.nextValue();
            parsedCase.flightDate = DateUtils.isValidIsoDatetime(
                parser.getText()
              )
              ? parser.getDatetimeValue()
              : null;
            parser.nextToken();
          }
          when 'lastModified' {
            parser.nextValue();
            parsedCase.lastModified = DateUtils.isValidIsoDatetime(
                parser.getText()
              )
              ? parser.getDatetimeValue()
              : null;
            parser.nextToken();
          }
          when 'dateClosed' {
            parser.nextValue();
            parsedCase.dateClosed = DateUtils.isValidIsoDatetime(
                parser.getText()
              )
              ? parser.getDatetimeValue()
              : null;
            parser.nextToken();
          }
          when 'caseId' {
            parser.nextValue();
            parsedCase.caseId = parser.getText();
            parser.nextToken();
          }
          when 'customerId' {
            parser.nextValue();
            parsedCase.customerId = parser.getText();
            parser.nextToken();
          }
          when 'pir' {
            parser.nextValue();
            parsedCase.pir = parser.getText();
            parser.nextToken();
          }
          when 'pnr' {
            parser.nextValue();
            parsedCase.pnr = parser.getText();
            parser.nextToken();
          }
          when 'flightNumber' {
            parser.nextValue();
            parsedCase.flightNumber = parser.getText();
            parser.nextToken();
          }
          when 'categories' {
            for (Object category : parseToList(parser, Categories.class)) {
              parsedCase.categories.add((Categories) category);
            }
          }
          when 'customers' {
            for (Object customer : parseToList(parser, Customers.class)) {
              parsedCase.customers.add((Customers) customer);
            }
          }
          when 'decisions' {
            for (Object decision : parseToList(parser, Decisions.class)) {
              parsedCase.decisions.add((Decisions) decision);
            }
          }
          when 'notes' {
            for (Object note : parseToList(parser, Notes.class)) {
              parsedCase.notes.add((Notes) note);
            }
          }
          when 'pnrs' {
            for (Object pnr : parseToList(parser, Pnrs.class)) {
              parsedCase.pnrs.add((Pnrs) pnr);
            }
          }
          when 'settlements' {
            parsedCase.settlements = parseSettlements(parser);
          }
        }
      }
    }

    return parsedCase;
  }

  private static List<Settlements> parseSettlements(JSONParser parser) {
    /**
     * Parsing tree here should be either
     * {
     *    "settlement": {...} // if there's only a single settlement
     * },
     * ...
     *
     * or
     *
     * {
     *   "settlement": [...] // if there is more than one settlement
     * },
     * ...
     */
    List<Settlements> parsedSettlements = new List<Settlements>();
    parser.nextToken(); // Skip START_OBJECT or jump to value string
    if (parser.getCurrentToken() == JSONToken.VALUE_STRING) {
      // If there are no values for a potential array, we get an empty string.
      parser.nextToken();
      return parsedSettlements;
    }

    parser.nextToken(); // Skip FIELD_NAME "settlement"

    JSONToken currentToken = parser.nextToken(); // Land on START_OBJECT or START_ARRAY

    switch on currentToken {
      when START_OBJECT {
        parsedSettlements.add(parseSingleSettlement(parser));
      }
      when START_ARRAY {
        while (currentToken != JSONToken.END_ARRAY) {
          if (currentToken == JSONToken.START_OBJECT) {
            parsedSettlements.add(parseSingleSettlement(parser));
            currentToken = parser.getCurrentToken();
          } else {
            currentToken = parser.nextToken();
          }
        }
        parser.nextToken(); // Skip END_ARRAY
      }
    }
    parser.nextToken(); // Skip top level END_OBJECT
    return parsedSettlements;
  }

  private static Settlements parseSingleSettlement(JSONParser parser) {
    Settlements parsedSettlement = new Settlements();

    JSONToken currentToken = parser.nextToken();
    while (currentToken != JSONToken.END_OBJECT) {
      switch on parser.getCurrentToken() {
        when FIELD_NAME {
          switch on parser.getCurrentName() {
            when 'amount' {
              parser.nextValue();
              parsedSettlement.amount = parser.getDecimalValue();
            }
            when 'amountInSEK' {
              parser.nextValue();
              parsedSettlement.amountInSEK = parser.getDecimalValue();
            }
            when 'dateSentToAmadeus' {
              parser.nextValue();
              parsedSettlement.dateSentToAmadeus = parser.getText();
            }
            when 'clmTransactionId' {
              parser.nextValue();
              parsedSettlement.clmTransactionId = parser.getText();
            }
            when 'type' {
              parser.nextValue();
              parsedSettlement.type = parser.getText();
            }
            when 'controlState' {
              parser.nextValue();
              parsedSettlement.controlState = parser.getText();
            }
            when 'csCategory' {
              parser.nextValue();
              parsedSettlement.csCategory = parser.getText();
            }
            when 'clmState' {
              parser.nextValue();
              parsedSettlement.clmState = parser.getText();
            }
            when 'bankDetails' {
              parser.nextValue();
              parsedSettlement.bankDetails = parser.getText();
            }
            when 'dateLastModified' {
              parser.nextValue();
              parsedSettlement.dateLastModified = parser.getText();
            }
            when 'dateCreated' {
              parser.nextValue();
              parsedSettlement.dateCreated = parser.getText();
            }
            when 'dateApproved' {
              parser.nextValue();
              parsedSettlement.dateApproved = parser.getText();
            }
            when 'caseId' {
              parser.nextValue();
              parsedSettlement.caseId = parser.getText();
            }
            when 'catName' {
              parser.nextValue();
              parsedSettlement.catName = parser.getText();
            }
            when 'customerId' {
              parser.nextValue();
              parsedSettlement.customerId = parser.getText();
            }
            when 'additionalInfo' {
              parser.nextValue();
              parsedSettlement.additionalInfo = parser.getText();
            }
            when 'settlementCurrency' {
              parser.nextValue();
              parsedSettlement.settlementCurrency = parser.getText();
            }
            when 'sEBState' {
              parser.nextValue();
              parsedSettlement.sEBState = parser.getText();
            }
            when 'settlementItem' {
              /**
               * Parsing tree should be here
               * "settlementItem": [
               *   {...items}
               * ],
               * or
               * "settlementItem: {
               *    // single item properties
               * }
               */
              currentToken = parser.nextToken(); // Land on START_OBJECT or START_ARRAY or VALUE_STRING
              switch on currentToken {
                when VALUE_STRING {
                  // If there are no values for a potential array, we get an empty string. We can just skip this
                  currentToken = parser.nextToken();
                }
                when START_OBJECT {
                  parsedSettlement.settlementItems.add(
                    (SettlementItems) parser.readValueAs(SettlementItems.class)
                  );
                  parser.skipChildren();
                }
                when START_ARRAY {
                  currentToken = parser.nextToken();
                  while (currentToken != JSONToken.END_ARRAY) {
                    if (currentToken == JSONToken.START_OBJECT) {
                      parsedSettlement.settlementItems.add(
                        (SettlementItems) parser.readValueAs(
                          SettlementItems.class
                        )
                      );
                      parser.skipChildren();
                    }
                    currentToken = parser.nextToken();
                  }
                }
              }
            }
          }
        }
      }
      currentToken = parser.nextToken();
    }
    parser.nextToken(); // Skip END_OBJECT
    return parsedSettlement;
  }
}
