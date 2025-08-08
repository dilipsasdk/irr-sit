public without sharing class ClaimRebookedFlight extends AbstractSObjectWrapper {
  public Claim_Rebooked_Flight__c underlyingSObject { get; private set; }

  public Id parentClaimId;
  public Date departureDate;
  public String flightNumber;

  public override void updateSObjectFields() {
    this.underlyingSObject.Claim__c = this.parentClaimId;
    this.underlyingSObject.Flight_Number__c = this.flightNumber;
    this.underlyingSObject.Departure_Date__c = this.departureDate;
  }
  private ClaimRebookedFlight() {
    this.underlyingSObject = new Claim_Rebooked_Flight__c();
  }

  public ClaimRebookedFlight(Claim parentClaim) {
    this();
    this.parentClaimId = parentClaim.id;
  }

  public ClaimRebookedFlight(Claim_Rebooked_Flight__c rebookedFlight) {
    super(rebookedFlight);
    this.underlyingSObject = rebookedFlight;

    this.departureDate = rebookedFlight.Departure_Date__c;
    this.flightNumber = rebookedFlight.Flight_Number__c;
  }
}
