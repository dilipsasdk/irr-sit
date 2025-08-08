public with sharing class VoucherCreateRequestV2 {
  public CustomerDetails customerDetails { get; private set; }
  public List<Voucher> vouchers { get; private set; }
  public String language { get; private set; }
  public String market { get; private set; }
  public String accessCode { get; private set; }
  public String businessReferenceNumber { get; private set; }
  public String type { get; private set; }
  public String notes { get; private set; }

  public class CustomerDetails {
    public String firstName { get; private set; }
    public String lastName { get; private set; }
    public String email { get; private set; }

    public CustomerDetails(String firstName, String lastName, String email) {
      this.firstName = firstName;
      this.lastName = lastName;
      this.email = email;
    }
  }

  public class Voucher {
    public Integer amount { get; private set; }
    public String voucherCurrency { get; private set; }

    public Voucher(Integer amount, String voucherCurrency) {
      this.amount = amount;
      this.voucherCurrency = voucherCurrency;
    }
  }

  public VoucherCreateRequestV2(
    VoucherOrchestrationService.VoucherType voucherType,
    String voucherCurrency,
    Integer amount,
    String firstName,
    String lastName,
    String email,
    String accessCode,
    String pnr,
    String market
  ) {
    this.customerDetails = new CustomerDetails(firstName, lastName, email);
    this.vouchers = new List<Voucher>{ new Voucher(amount, voucherCurrency) };
    this.market = market;
    this.language = 'en';
    this.accessCode = accessCode;
    this.businessReferenceNumber = pnr;
    this.type = String.valueOf(voucherType);
    this.notes = 'Voucher created by Salesforce';
  }
}
