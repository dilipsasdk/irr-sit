public without sharing class Airport extends AbstractSObjectWrapper {
  public static final Integer CANADA_EAST_COAST_LONGITUDE = -50;

  public Airport__c underlyingSObject { get; private set; }

  public String city;
  public String countryCode;
  public String countryName;
  public Boolean isEU261Applicable;
  public Decimal latitude;
  public Decimal longitude;
  public String tedsIdentifier;

  public class AirportException extends Exception {
  }

  public class AirportsNotDefinedException extends Exception {
  }

  @TestVisible
  private Airport() {
    this.underlyingSObject = new Airport__c();
  }

  public Airport(Airport__c a) {
    super(a);
    this.underlyingSObject = a;

    this.city = a.City__c;
    this.countryCode = a.Country_Code__c;
    this.countryName = a.Country_Name__c;
    this.isEU261Applicable = a.Is_EU261_Applicable__c;
    this.latitude = a.Latitude__c;
    this.longitude = a.Longitude__c;
    this.tedsIdentifier = a.TEDS_Identifier__c;
  }

  public override void updateSObjectFields() {
    this.underlyingSObject.City__c = this.city;
    this.underlyingSObject.Country_Code__c = this.countryCode;
    this.underlyingSObject.Country_Name__c = this.countryName;
    this.underlyingSObject.Is_EU261_Applicable__c = this.isEU261Applicable;
    this.underlyingSObject.Latitude__c = this.latitude;
    this.underlyingSObject.Longitude__c = this.longitude;
    this.underlyingSObject.TEDS_Identifier__c = this.tedsIdentifier;
  }

  /**
   * Calculates the haversine distance in meters from this airport to the other
   * given airport.
   */
  public Integer distanceInMetersTo(Airport otherAirport) {
    return distanceBetweenAirportsInMeters(this, otherAirport);
  }

  /**
   * Calculates the haversine distance in meters between two airports.
   *
   * @return An Integer value of the distance in meters between the two airports.
   */
  public static Integer distanceBetweenAirportsInMeters(
    Airport airport1,
    Airport airport2
  ) {
    if (airport1 == null || airport2 == null) {
      throw new AirportsNotDefinedException(
        'At least one of the airports equal to null.'
      );
    }

    Location loc1 = Location.newInstance(airport1.latitude, airport1.longitude);
    Location loc2 = Location.newInstance(airport2.latitude, airport2.longitude);
    Double dist = Location.getDistance(loc1, loc2, 'km'); // Can only be km or mi

    if (dist == null) {
      throw new AirportException('Airport longitude and/or latitude not set');
    }

    return Integer.valueOf(
      Decimal.valueOf(dist * 1000).round(System.RoundingMode.HALF_UP)
    );
  }

  /**
   * DEPRECATED as of 2023-11-07
   * Left here if issues reimurge.
   * 
   * If the airport is far to the west (e.g. in the US) it might be
   * affected by a EDW local time bug where the departure date is
   * incorrect, leading to an incorrect tedsIdentifier
   */
  public Boolean hasProblematicTimeZoneDifferenceToUTC() {
    Boolean isWestOfCanadasEastCoast =
      this.longitude < CANADA_EAST_COAST_LONGITUDE;
    return isWestOfCanadasEastCoast;
  }
}
