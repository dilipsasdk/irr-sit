public without sharing class Airports extends ApplicationDomain {
  public Airports(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Airport__c>) Records;

    List<Airport> airportObjects = new List<Airport>();
    for (Airport__c a : this.instanceRecords) {
      airportObjects.add(new Airport(a));
    }

    this.objects = airportObjects;
  }

  public List<Airport__c> instanceRecords;
  public List<Airport> objects;

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new Airports(records);
    }
  }

  public static Airports newInstance(List<Airport__c> sObjectList) {
    return (Airports) SAS_Service_Application.Domain.newInstance(sObjectList);
  }

  public override void onBeforeInsert() {
    for (Airport__c a : instanceRecords) {
      a.Is_EU261_Applicable__c = CountryUtils.isInEUOrNorwaySwitzerlandIceland(
        a.Country_Code__c
      );
    }
  }

  public Airports upsertToDB() {
    for (Airport obj : this.objects) {
      obj.updateSObjectFields();
    }
    try {
      upsert instanceRecords TEDS_Identifier__c;
    } catch (DMLException e) {
      if (e.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
        upsert instanceRecords TEDS_Identifier__c;
      }
    }

    List<Airport> airports = new List<Airport>();
    for (Airport__c a : this.instanceRecords) {
      airports.add(new Airport(a));
    }
    this.objects = airports;

    return this;
  }

  /**
   * Parses airport data in TEDSAirport format into Airport__c objects and prepares them for DB insertion.
   *
   * @param airportData List of TEDSAirport objects containing Airports to create.
   * @param shouldUpsertToDB Boolean which asserts whether the records should be upserted or not
   *
   * @return The list of created Airport__c objects.
   */
  public static Airports createFromTEDSData(
    List<TEDSAirport> airportData,
    Boolean shouldUpsertToDB
  ) {
    Map<String, Airport__c> airportsProcessed = new Map<String, Airport__c>();

    for (TEDSAirport airport : airportData) {
      String airportId = airport.id.trim().toUpperCase();

      // TODO: Examine if we can manually set the id some way (Id = airportId)
      if (!airportsProcessed.containsKey(airportId)) {
        Airport__c newairport = new Airport__c(
          Name = airport.name,
          City__c = airport.city,
          Country_Code__c = airport.country.code,
          Country_Name__c = airport.country.name,
          Latitude__c = Decimal.valueOf(airport.coordinates.latitude)
            .setScale(12),
          Longitude__c = Decimal.valueOf(airport.coordinates.longitude)
            .setScale(12),
          Is_EU261_Applicable__c = CountryUtils.isInEUOrNorwaySwitzerlandIceland(
            airport.country.code
          ),
          TEDS_Identifier__c = airportId
        );

        airportsProcessed.put(airportId, newairport);
      }
    }

    Airports newAirports = Airports.newInstance(airportsProcessed.values());
    List<String> TEDSIds = new List<String>(airportsProcessed.keySet());

    if (shouldUpsertToDB) {
      newAirports.upsertToDB();
    }

    return newAirports;
  }

  // TODO: What to do with this? Part of a service? Or in here?
  /**
   * Calculates the haversine distance in meters between two airports.
   *
   * @param airport1 a String with the IATA code of the airport e.g. ARN.
   * @param airport2 a String with the IATA code of the airport e.g. ARN.
   *
   * TODO: No selector calls in domains unless 100% mandatory.
   *
   * @return An Integer value of the distance in meters between the two airports.
   */
  public static Integer distanceBetweenAirportsInMeters(
    String airport1,
    String airport2
  ) {
    List<Airport__c> airports = AirportsSelector.newInstance()
      .selectByIATACode(new Set<String>{ airport1, airport2 });

    if (airports.size() != 2) {
      throw new AirportsNotDefinedException('Unable to find airports');
    }

    return Airport.distanceBetweenAirportsInMeters(
      new Airport(airports[0]),
      new Airport(airports[1])
    );
  }

  // For manual update
  public void setEU261Applicable() {
    for (Airport__c a : instanceRecords) {
      a.Is_EU261_Applicable__c = CountryUtils.isInEUOrNorwaySwitzerlandIceland(
        a.Country_Code__c
      );
    }
    update instanceRecords;
  }

  public class AirportsNotDefinedException extends Exception {
  }

  public Map<String, Airport__c> getAirportCodeToAirport() {
    Map<String, Airport__c> codeToAirport = new Map<String, Airport__c>{};
    for (Airport__c a : instanceRecords) {
      codeToAirport.put(a.TEDS_Identifier__c, a);
    }
    return codeToAirport;
  }

  public Map<String, Airport> getAirportCodeToAirportObject() {
    Map<String, Airport> codeToAirport = new Map<String, Airport>{};
    for (Airport__c a : instanceRecords) {
      codeToAirport.put(a.TEDS_Identifier__c, new Airport(a));
    }
    return codeToAirport;
  }
}
