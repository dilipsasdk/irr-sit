@IsTest
public with sharing class TestFlightFactory {
  public static Flight create(
    String flightNumber,
    DateTime flightDateTime,
    String departure,
    String arrival
  ) {
    Airport departureAirport = TestAirportFixture.codeToAirport.get(departure);
    Airport arrivalAirport = TestAirportFixture.codeToAirport.get(arrival);

    String tedsIdentifier =
      flightNumber +
      '-' +
      StringUtils.dateToTEDSString(flightDateTime.date()) +
      '-' +
      departure +
      '-' +
      arrival;

    Flight f = new Flight();
    f.id = fflib_IDGenerator.generate(Flight__c.getSObjectType());
    f.tedsIdentifier = tedsIdentifier;

    f.departureAirportObject = departureAirport;
    f.arrivalAirportObject = arrivalAirport;

    f.operationalControlCenter = null; // TODO: implement
    f.aircraftRegistration = null; // TODO: implement
    f.operatingCarrier = flightNumber.substring(0, 2);

    f.arrivalAirport = arrival;
    f.arrivalDelayedMinutes = 0;
    f.arrivalGate = 'A1';
    f.arrivalStatus = Flight.Status.Ontime;
    f.arrivalTerminal = '1';

    f.departureAirport = departure;
    f.departureDelayedMinutes = 0;
    f.departureGate = 'A1';
    f.departureStatus = Flight.Status.Ontime;
    f.departureTerminal = '1';

    f.actualArrivalTime = flightDateTime.addHours(2);
    f.actualArrivalTimeLocal = String.valueOf(flightDateTime.addHours(2));
    f.actualDepartureTime = flightDateTime;
    f.actualDepartureTimeLocal = String.valueOf(flightDateTime);

    f.estimatedArrivalTime = flightDateTime.addHours(2);
    f.estimatedArrivalTimeLocal = String.valueOf(flightDateTime.addHours(2));
    f.estimatedDepartureTime = flightDateTime;
    f.estimatedDepartureTimeLocal = String.valueOf(flightDateTime);

    f.scheduledArrivalTime = flightDateTime.addHours(2);
    f.scheduledArrivalTimeLocal = String.valueOf(flightDateTime.addHours(2));
    f.scheduledDepartureTime = flightDateTime;
    f.scheduledDepartureTimeLocal = String.valueOf(flightDateTime);

    f.irregularities = new List<FlightIrregularity>();

    return f;
  }
}
