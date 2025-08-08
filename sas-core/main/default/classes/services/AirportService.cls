public without sharing class AirportService {
  public static AirportService newInstance() {
    return (AirportService) SAS_Service_Application.Service.newInstance(
      AirportService.class
    );
  }

  public class IllegalArgumentsException extends Exception {
  }

  /**
   * Attempts to fetch the given airports from TEDS, and create necessary DB objects.
   * Does nothing if one isn't found.
   *
   * @param airportReferences Set of airports to find using the full TEDS airport Id. Maximum of 10 per call.
   *
   * @throws IntegrationError If there is a problem with the integration.
   * @throws IllegalArgumentsException If there are no airport references.
   */
  public Airports fetchAirportsByReference(
    Set<String> airportReferences,
    Boolean shouldUpsertToDB
  ) {
    return fetchAirportsByReferenceStatic(airportReferences, shouldUpsertToDB);
  }

  public static Airports fetchAirportsByReferenceStatic(
    Set<String> airportReferences,
    Boolean shouldUpsertToDB
  ) {
    if (airportReferences == null || airportReferences.size() == 0) {
      throw new IllegalArgumentsException('AirportReferences cannot be empty.');
    }

    TEDSIntegrationService.AirportsQuery query = new TEDSIntegrationService.AirportsQuery();
    query.ids = airportReferences;

    List<TEDSAirport> airportData = TEDSIntegrationService.newInstance()
      .fetchAirportsByQuery(query);

    if (airportData.size() == 0) {
      // Not found in TEDS.
      // TODO: Would it make more sense to return an instance of Airports, but
      // with no instance records?
      return null;
    }

    Airports newAirports = Airports.createFromTEDSData(
      airportData,
      shouldUpsertToDB
    );

    return newAirports;
  }
}
