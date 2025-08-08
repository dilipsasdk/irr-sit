public without sharing class ClaimCustomer extends AbstractSObjectWrapper {
  public Customer__c underlyingSObject { get; private set; }

  public Id parentClaimId;
  public String firstName;
  public String lastName;

  public String fullName {
    get {
      return this.firstName + ' ' + this.lastName;
    }
  }

  public String normalizedFullName {
    get {
      return Passenger.normalizeName(this.fullName);
    }
  }

  public String normalizedLastName {
    get {
      return Passenger.normalizeName(this.lastName);
    }
  }

  public override void updateSObjectFields() {
    this.underlyingSObject.First_Name__c = this.firstName;
    this.underlyingSObject.Last_Name__c = this.lastName;
    this.underlyingSObject.Claim__c = this.parentClaimId;
  }

  @TestVisible
  private ClaimCustomer() {
    this.underlyingSObject = new Customer__c();
  }

  public ClaimCustomer(Claim parentClaim) {
    this();
    this.parentClaimId = parentClaim.id;
  }

  public ClaimCustomer(Customer__c c) {
    super(c);
    this.underlyingSObject = c;
    this.firstName = c.First_Name__c;
    this.lastName = c.Last_Name__c;
    this.parentClaimId = c.Claim__c;
  }

  public Integer hashCode() {
    if (this.underlyingSObject != null && this.underlyingSObject.Id != null) {
      return String.valueOf(this.underlyingSObject.Id).hashCode();
    } else {
      return this.fullName.hashCode();
    }
  }

  public override String toString() {
    return this.fullName;
  }
}
