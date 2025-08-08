public without sharing class ProactivityService {
  public static ProactivityService newInstance() {
    return (ProactivityService) SAS_Service_Application.Service.newInstance(
      ProactivityService.class
    );
  }

  public static void createAutomationProactivitiesFromFlightIds(
    Set<Id> flightIds
  ) {
    List<Flight__c> flights = FlightsSelector.newInstance()
      .selectById(flightIds);
    List<FlightIrregularities__c> allIrregularities = FlightIrregularitiesSelector.newInstance()
      .selectByFlightId(flightIds);

    Map<Id, List<FlightIrregularities__c>> flightToIrregularities = new FlightIrregularities(
        allIrregularities
      )
      .getFlightIdToIrregularities();

    Set<Flight> flightObjects = new Set<Flight>();
    for (Flight__c f : flights) {
      List<FlightIrregularities__c> irrs = flightToIrregularities.get(f.Id);
      List<FlightIrregularity> irrObjects = new List<FlightIrregularity>();
      for (FlightIrregularities__c irr : irrs) {
        irrObjects.add(new FlightIrregularity(irr));
      }

      Flight fl = new Flight(f);
      fl.irregularities = irrObjects;
      flightObjects.add(fl);
    }

    createAutomationProactivities(flightObjects);
  }

  private static void createAutomationProactivities(Set<Flight> flights) {
    List<Proactivity__c> toInsert = new List<Proactivity__c>();
    for (Flight f : flights) {
      Proactivity__c p = createFromFlightWithIrregularity(f);
      if (p != null) {
        toInsert.add(p);
      }
    }

    if (toInsert.size() > 0) {
      insert toInsert;
    }
  }

  /**
   * Creates an automation proactivity if possible, otherwise returns null
   */
  private static Proactivity__c createFromFlightWithIrregularity(Flight f) {
    // If there are more than one irregularity, we cannot be sure what the
    // root cause is.
    if (f.irregularities.size() != 1) {
      return null;
    }

    FlightIrregularity fi = f.irregularities[0];
    if (fi.code == null || fi.reason == null) {
      return null;
    }
    fi.setEligibility(); // If not already set

    if (fi.description == null || fi.eligibleForEU261 == null) {
      return null;
    }

    Proactivity__c p = new Proactivity__c();
    p.Flight_Id__c = Flight.TEDSIdToSimpleFlightIds(f.tedsIdentifier)[0];
    p.Type__c = 'Automatically Created';
    p.Automate_Matching_Claims__c = false; // This is done on-demand in the irregularity
    p.Note__c = fi.description;
    p.Eligibility_Explanation__c = fi.description;
    p.EU261_Eligibility__c = fi.eligibleForEU261.name();

    return p;
  }
}
