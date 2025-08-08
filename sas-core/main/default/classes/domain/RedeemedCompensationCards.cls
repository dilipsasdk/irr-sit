public without sharing class RedeemedCompensationCards extends ApplicationDomain {
  public RedeemedCompensationCards(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Redeemed_Compensation_Card__c>) Records;
  }

  public List<Redeemed_Compensation_Card__c> instanceRecords;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new RedeemedCompensationCards(records);
    }
  }

  public static RedeemedCompensationCards newInstance(
    List<Redeemed_Compensation_Card__c> sObjectList
  ) {
    return (RedeemedCompensationCards) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }

  public static Boolean hasBeenPaidOut(
    String cardNumber,
    String bookingReference
  ) {
    return !RedeemedCompensationCardsSelector.newInstance()
      .selectByCardNumberAndBookingReference(cardNumber, bookingReference)
      .isEmpty();
  }

  public static Boolean hasBeenPaidOut(String cardNumber) {
    return !RedeemedCompensationCardsSelector.newInstance()
      .selectByCardNumber(cardNumber)
      .isEmpty();
  }

  public static RedeemedCompensationCards createFromValidVoucher(
    VoucherValidateResponse voucherResponse,
    LIA_Claim__c claim,
    fflib_ISObjectUnitOfWork uow
  ) {
    Redeemed_Compensation_Card__c cc = new Redeemed_Compensation_Card__c(
      Amount__c = voucherResponse.amount,
      Booking_Reference__c = voucherResponse.pnr,
      Claim__c = claim.Id,
      Compensation_Card_Number__c = claim.Compensation_Card_Number__c,
      Currency__c = voucherResponse.voucherCurrency,
      Email__c = voucherResponse.email,
      First_Name__c = voucherResponse.firstName,
      Flight_Date__c = String.isBlank(voucherResponse.flightDate)
        ? null
        : Date.valueOf(voucherResponse.flightDate),
      Flight_Number__c = voucherResponse.flightNumber.replaceAll(' ', ''),
      Last_Name__c = voucherResponse.lastName,
      Phone__c = voucherResponse.phone,
      Service_Class__c = voucherResponse.serviceClass,
      Sub_Type__c = voucherResponse.subType,
      Ticket_Number__c = voucherResponse.ticketNumber,
      Type__c = voucherResponse.type
    );

    uow.registerNew(cc);
    return newInstance(new List<Redeemed_Compensation_Card__c>{ cc });
  }

  public static RedeemedCompensationCards createFromValidVoucher(
    VoucherValidateResponseV2 voucherResponse,
    LIA_Claim__c claim,
    fflib_ISObjectUnitOfWork uow
  ) {
    Redeemed_Compensation_Card__c cc = new Redeemed_Compensation_Card__c(
      Amount__c = voucherResponse.balance,
      Booking_Reference__c = voucherResponse.flightDetails?.pnr,
      Claim__c = claim.Id,
      Compensation_Card_Number__c = claim.Compensation_Card_Number__c,
      Currency__c = voucherResponse.voucherCurrency,
      Email__c = voucherResponse.customerDetails.email,
      First_Name__c = voucherResponse.customerDetails.firstName,
      Flight_Date__c = String.isBlank(voucherResponse.flightDetails?.flightDate)
        ? null
        : Date.valueOf(voucherResponse.flightDetails.flightDate),
      Flight_Number__c = voucherResponse.flightDetails?.flightNumber?.replaceAll(
        ' ',
        ''
      ),
      Last_Name__c = voucherResponse.customerDetails.lastName,
      Phone__c = voucherResponse.customerDetails.phoneNumber,
      Sub_Type__c = voucherResponse.type,
      Type__c = String.valueOf(VoucherIntegrationService.VoucherType.COMP)
    );

    uow.registerNew(cc);
    return newInstance(new List<Redeemed_Compensation_Card__c>{ cc });
  }

  public override void onApplyDefaults() {
    for (Redeemed_Compensation_Card__c cc : instanceRecords) {
      cc.Name = cc.Compensation_Card_Number__c;
    }
  }
}
