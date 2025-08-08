public without sharing class Passenger extends AbstractSObjectWrapper {
  public Passenger__c underlyingSObject { get; private set; }

  public Id accountId;
  public Id bookingId;

  public String email;
  public String euroBonusNumber;
  public String firstName;
  public String identifier;
  public String lastName;
  public String phone;

  public String normalizedFullName {
    get {
      return normalizeName(this.firstName + ' ' + this.lastName);
    }
  }

  @TestVisible
  private Passenger() {
    this.underlyingSObject = new Passenger__c();
  }

  public Passenger(Passenger__c p) {
    super(p);
    this.underlyingSObject = p;

    this.accountId = p.Account__c;
    this.bookingId = p.Booking__c;
    this.email = p.Email__c;
    this.euroBonusNumber = p.EuroBonus_Number__c;
    this.firstName = p.First_Name__c;
    this.identifier = p.Identifier__c;
    this.lastName = p.Last_Name__c;
    this.phone = p.Phone__c;
  }

  public override void updateSObjectFields() {
    this.underlyingSObject.Account__c = this.accountId;
    this.underlyingSObject.Booking__c = this.bookingId;
    this.underlyingSObject.Email__c = this.email;
    this.underlyingSObject.EuroBonus_Number__c = this.euroBonusNumber;
    this.underlyingSObject.First_Name__c = this.firstName;
    this.underlyingSObject.Identifier__c = this.identifier;
    this.underlyingSObject.Last_Name__c = this.lastName;
    this.underlyingSObject.Phone__c = this.phone;
  }

  public static String normalizeName(String name) {
    return StringUtils.removeWhitespace(StringUtils.scandicsToASCII(name))
      .replaceAll('-', '')
      .toLowerCase();
  }
}
