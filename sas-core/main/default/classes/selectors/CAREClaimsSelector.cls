public inherited sharing class CAREClaimsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      CARE_Claim__c.Id,
      CARE_Claim__c.Booking_Reference__c,
      CARE_Claim__c.Case_Id__c,
      CARE_Claim__c.Date_Created_In_CARE__c,
      CARE_Claim__c.Flight_Number__c,
      CARE_Claim__c.Name,
      CARE_Claim__c.PIR__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return CARE_Claim__c.SObjectType;
  }

  public static CAREClaimsSelector newInstance() {
    return (CAREClaimsSelector) SAS_Service_Application.Selector.newInstance(
      CARE_Claim__c.SObjectType
    );
  }

  public List<CARE_Claim__c> selectById(Set<Id> ids) {
    return (List<CARE_Claim__c>) selectSObjectsById(ids);
  }

  public List<CARE_Claim__c> selectSimilarCasesById(Id caseId) {
    List<LIA_Claim__c> claims = ClaimsSelector.newInstance()
      .selectByCaseIdWithCustomers(new Set<Id>{ caseId });
    if (claims == null || claims.size() == 0) {
      return new List<CARE_Claim__c>();
    }

    LIA_Claim__c claimForCase = claims[0];

    String bookingReference = claimForCase.Liability_PNR__c;
    String pirNumber = claimForCase.PIR__c;

    String whereQuery = '';

    if (!String.isBlank(bookingReference)) {
      whereQuery += 'Booking_Reference__c = :bookingReference';
    }

    if (!String.isBlank(pirNumber)) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'PIR__c = :pirNumber';
      } else {
        whereQuery += ' OR PIR__c = :pirNumber';
      }
    }

    return (List<CARE_Claim__c>) Database.query(
      newQueryFactory().setCondition(whereQuery).toSOQL()
    );
  }

  public List<CARE_Claim__c> selectByQuery(
    String caseId,
    String pir,
    String bookingReference
  ) {
    String whereQuery = '';

    if (!String.isBlank(bookingReference)) {
      whereQuery += 'Booking_Reference__c = :bookingReference';
    }

    if (!String.isBlank(pir)) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'PIR__c = :pir';
      } else {
        whereQuery += ' OR PIR__c = :pir';
      }
    }

    if (!String.isBlank(caseId)) {
      if (String.isBlank(whereQuery)) {
        whereQuery += 'Case_Id__c = :caseId';
      } else {
        whereQuery += ' OR Case_Id__c = :caseId';
      }
    }

    return (List<CARE_Claim__c>) Database.query(
      newQueryFactory().setCondition(whereQuery).toSOQL()
    );
  }

  /**
   * Select potential duplicates for EU261 claims. Potential duplicate is
   * defined as having the same booking reference and claimed flight number.
   * 
   * @param pnrFlightNumberTuples A list of (bookingReference, flightNumber) pairs with which to query.
   */
  public List<CARE_Claim__c> selectPotentialDuplicates(
    List<List<String>> pnrFlightNumberTuples
  ) {
    Set<String> duplicateMatchers = new Set<String>();

    for (List<String> pnrAndFlightNumber : pnrFlightNumberTuples) {
      duplicateMatchers.add(
        pnrAndFlightNumber[0] +
        '-' +
        pnrAndFlightNumber[1]
      );
    }

    return (List<CARE_Claim__c>) Database.query(
      newQueryFactory()
        .setCondition('Duplicate_Matcher__c IN :duplicateMatchers')
        .toSOQL()
    );
  }
}
