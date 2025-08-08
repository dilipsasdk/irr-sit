@IsTest
public with sharing class TestClaimFactory {
  public static Claim create() {
    Claim c = new Claim();
    Date t = Date.today();
    t.addDays(-1); // Make sure we don't create a claim in the future

    c.createdDate = DateTime.newInstance(t.year(), t.month(), t.day(), 0, 1, 0);
    c.contactAddressLine1 = 'Frösundaviks Allé 1';
    c.contactAddressLine2 = '';
    c.bankAccountHolderName = 'Test';
    c.bankAccountNumber = 'SE7280000810340009783242'; // Source: https://www.iban.com/structure
    c.bankCountry = 'Sweden';
    c.bankName = 'SASBank';
    c.bankBicSwift = 'SASBSESE';
    c.parentCaseId = null;
    c.contactCity = 'Stockholm';
    c.comment = '';
    c.companyCode = '';
    c.companyName = '';
    c.compensationCardNumber = '';
    c.personWithReducedMobility = false;
    c.unaccompaniedMinor = false;
    c.contactEmail = 'test@example.com';
    c.contactFirstName = 'Test';
    c.contactLastName = 'Testsson';
    c.contactCountry = 'Sweden';
    c.preferredCurrency = Money.CurrencyCode.EUR;
    c.category = null;
    c.type = null;
    c.euroBonusNumber = '000000000';
    c.bookingReference = 'ABC123';
    c.contactPhone = '0000000000';
    c.contactPostalCode = '16970';
    c.preferredCompensationMethod = Claim.CompensationType.Monetary;
    c.preferredReimbursementMethod = Claim.CompensationType.Monetary;
    c.recordType = Claim.RecordType.CustomerClaim;
    c.contactType = Claim.ContactType.PrivateCustomer;

    return c;
  }
}
