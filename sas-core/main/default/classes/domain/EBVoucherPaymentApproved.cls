public without sharing class EBVoucherPaymentApproved extends ApplicationDomain {
  public EBVoucherPaymentApproved(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<EBVoucherPaymentApproved__e>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new EBVoucherPaymentApproved(records);
    }
  }

  public static EBVoucherPaymentApproved newInstance(
    List<EBVoucherPaymentApproved__e> sObjectList
  ) {
    return (EBVoucherPaymentApproved) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }

  public List<EBVoucherPaymentApproved__e> instanceRecords;

  public override void onAfterInsert() {
    for (EBVoucherPaymentApproved__e event : instanceRecords) {
      SettlementService.processPayableSettlement(event.Settlement__c);
    }
  }
}
