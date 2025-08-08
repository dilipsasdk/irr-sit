global with sharing class EU261ClaimPNRResponse {
  global List<EU261ClaimInfo> pnrList;
  public EU261ClaimPNRResponse(List<LIA_Claim__c> toReturn) {
    this.pnrList = new List<EU261ClaimInfo>();
    for (LIA_Claim__c cl : toReturn) {
      try {
        cl = sanitize(cl);
      } catch (SanitizationException e) {
        continue;
      }
      this.pnrList.add(new EU261ClaimInfo(cl));
    }
  }

  global class EU261ClaimInfo {
    global Id claimId;
    global String pnr;
    global String flightNumber;
    global Date flightDate;
    public EU261ClaimInfo(LIA_Claim__c claim) {
      this.claimId = claim.Id;
      this.pnr = claim.Liability_PNR__c;
      this.flightNumber = claim.Flight_Number__c;
      this.flightDate = claim.Flight_Date__c;
    }
  }

  public class SanitizationException extends Exception {
  }

  private static LIA_Claim__c sanitize(LIA_Claim__c cl) {
    if (
      cl.Liability_PNR__c == null ||
      cl.Flight_Number__c == null ||
      cl.Flight_Date__c == null
    ) {
      throw new SanitizationException(
        'PNR, Flight Number, and Flight Date are required'
      );
    } else if (
      cl.Liability_PNR__c.length() < 6 ||
      cl.Flight_Number__c.length() < 6
    ) {
      throw new SanitizationException(
        'PNR and Flight Number must be at least 6 characters'
      );
    }

    if (cl.Liability_PNR__c.length() > 6) {
      cl.Liability_PNR__c = cl.Liability_PNR__c.substring(0, 6);
    }
    if (cl.Flight_Number__c.length() > 6) {
      cl.Flight_Number__c = cl.Flight_Number__c.substring(0, 6);
    }
    return cl;
  }
}
