public inherited sharing class RedeemedCompensationCardsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Redeemed_Compensation_Card__c.Id,
      Redeemed_Compensation_Card__c.Amount__c,
      Redeemed_Compensation_Card__c.Booking_Reference__c,
      Redeemed_Compensation_Card__c.Currency__c,
      Redeemed_Compensation_Card__c.Email__c,
      Redeemed_Compensation_Card__c.First_Name__c,
      Redeemed_Compensation_Card__c.Flight_Date__c,
      Redeemed_Compensation_Card__c.Flight_Number__c,
      Redeemed_Compensation_Card__c.Last_Name__c,
      Redeemed_Compensation_Card__c.Phone__c,
      Redeemed_Compensation_Card__c.Service_Class__c,
      Redeemed_Compensation_Card__c.Sub_Type__c,
      Redeemed_Compensation_Card__c.Ticket_Number__c,
      Redeemed_Compensation_Card__c.Type__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Redeemed_Compensation_Card__c.SObjectType;
  }

  public static RedeemedCompensationCardsSelector newInstance() {
    return (RedeemedCompensationCardsSelector) SAS_Service_Application.Selector.newInstance(
      Redeemed_Compensation_Card__c.SObjectType
    );
  }

  public List<Redeemed_Compensation_Card__c> selectById(Set<Id> ids) {
    return (List<Redeemed_Compensation_Card__c>) selectSObjectsById(ids);
  }

  public List<Redeemed_Compensation_Card__c> selectByClaimId(Set<Id> claimIds) {
    return (List<Redeemed_Compensation_Card__c>) Database.query(
      newQueryFactory().setCondition('Claim__c IN :claimIds').toSOQL()
    );
  }

  public List<Redeemed_Compensation_Card__c> selectByCardNumberAndBookingReference(
    String cardNumber,
    String bookingReference
  ) {
    return (List<Redeemed_Compensation_Card__c>) Database.query(
      newQueryFactory()
        .setCondition(
          'Compensation_Card_Number__c = :cardNumber AND Booking_Reference__c = :bookingReference'
        )
        .toSOQL()
    );
  }

  public List<Redeemed_Compensation_Card__c> selectByCardNumber(
    String cardNumber
  ) {
    return (List<Redeemed_Compensation_Card__c>) Database.query(
      newQueryFactory()
        .setCondition('Compensation_Card_Number__c = :cardNumber')
        .toSOQL()
    );
  }
}
