public inherited sharing class SettlementsSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Settlement__c.Id,
      Settlement__c.Name,
      Settlement__c.CreatedDate,
      Settlement__c.LastModifiedDate,
      Settlement__c.Address_line_1__c,
      Settlement__c.Address_line_2__c,
      Settlement__c.Amount__c,
      Settlement__c.Bank_Account_Number__c,
      Settlement__c.Bank_Country__c,
      Settlement__c.BIC_Swift__c,
      Settlement__c.City__c,
      Settlement__c.Claim__c,
      Settlement__c.Country__c,
      Settlement__c.Currency__c,
      Settlement__c.Date_of_Payment__c,
      Settlement__c.EuroBonus_Number__c,
      Settlement__c.EuroBonus_Points__c,
      Settlement__c.IsEmergencyClaim__c,
      Settlement__c.Payee_First_Name__c,
      Settlement__c.Payee_Last_Name__c,
      Settlement__c.Payee_Name__c,
      Settlement__c.Payee_reference__c,
      Settlement__c.Postal_Code__c,
      Settlement__c.RecordTypeId,
      Settlement__c.Settlement_Status__c,
      Settlement__c.Voucher_Email__c,
      Settlement__c.Voucher_Type__c,
      Settlement__c.State__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Settlement__c.SObjectType;
  }

  public static SettlementsSelector newInstance() {
    return (SettlementsSelector) SAS_Service_Application.Selector.newInstance(
      Settlement__c.SObjectType
    );
  }

  public List<Settlement__c> selectById(Set<Id> ids) {
    return (List<Settlement__c>) selectSObjectsById(ids);
  }

  public List<Settlement__c> selectByName(Set<String> names) {
    return (List<Settlement__c>) Database.query(
      newQueryFactory().setCondition('Name IN :names').toSOQL()
    );
  }

  public List<Settlement__c> selectByClaimId(Set<Id> claimIds) {
    return (List<Settlement__c>) Database.query(
      newQueryFactory().setCondition('Claim__c IN :claimIds').toSOQL()
    );
  }

  public List<Settlement__c> selectByIdWithClaimFields(Set<Id> ids) {
    return (List<Settlement__c>) Database.query(
      newQueryFactory()
        .setCondition('Id IN :ids')
        .selectField('Claim__r.Liability_PNR__c')
        .selectField('Claim__r.Name')
        .selectField('Claim__r.Case__c')
        .selectField('Claim__r.Case__r.CaseNumber')
        .selectField('Submitter__r.Email')
        .toSOQL()
    );
  }

  public List<Settlement__c> selectByIdWithSettlementItems(Set<Id> ids) {
    fflib_QueryFactory query = newQueryFactory()
      .setCondition('Id IN :ids')
      .selectField('Claim__r.Customer_Claim_Category__c');
    fflib_QueryFactory settlementItems = new SettlementItemsSelector()
      .addQueryFactorySubselect(query);

    return (List<Settlement__c>) Database.query(query.toSOQL());
  }

  public List<Settlement__c> selectWaitingForTransferByCurrency(
    List<String> currencies
  ) {
    String statusToTake = Settlements.STATUS_WAITING_FOR_TRANSFER;
    Set<Id> recordTypeIdsToTake = new Set<Id>();

    recordTypeIdsToTake.add(
      Settlements.getRecordTypeId(Settlements.RecordType.Cheque)
    );
    recordTypeIdsToTake.add(
      Settlements.getRecordTypeId(Settlements.RecordType.Monetary)
    );

    return (List<Settlement__c>) Database.query(
      newQueryFactory()
        .setCondition(
          'Settlement_Status__c =:statusToTake AND Currency__c in :currencies AND Control_verified__c = true AND RecordTypeId IN :recordTypeIdsToTake'
        )
        .toSOQL()
    );
  }

  public List<Settlement__c> selectEurobonusAndVoucherWaitingForTransfer() {
    String statusToTake = Settlements.STATUS_WAITING_FOR_TRANSFER;
    Set<Id> recordTypeIdsToTake = new Set<Id>();

    recordTypeIdsToTake.add(
      Settlements.getRecordTypeId(Settlements.RecordType.Voucher)
    );
    recordTypeIdsToTake.add(
      Settlements.getRecordTypeId(Settlements.RecordType.EBPoints)
    );

    return (List<Settlement__c>) Database.query(
      newQueryFactory()
        .setCondition(
          'Settlement_Status__c =:statusToTake AND Control_verified__c = true AND RecordTypeId IN :recordTypeIdsToTake'
        )
        .toSOQL()
    );
  }

  public List<Settlement__c> selectByPaymentFileName(String paymentFileName) {
    return (List<Settlement__c>) Database.query(
      newQueryFactory()
        .setCondition('Payment_File_Name__c =:paymentFileName')
        .toSOQL()
    );
  }

  public override String getOrderBy() {
    return 'Name';
  }
}
