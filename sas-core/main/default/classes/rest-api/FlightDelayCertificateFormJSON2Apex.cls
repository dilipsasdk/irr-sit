global class FlightDelayCertificateFormJSON2Apex {
  global FormData formData;
  global MetaData metaData;

  global class FormData {
    global String bookingReference;
    global String firstName;
    global String lastName;
    global String email;
    global String departureDate; // 2022-02-20
    global String flightNumber; // SK1234
  }

  global class MetaData {
    global String market;
  }

  public static FlightDelayCertificateFormJSON2Apex parse(String json) {
    return (FlightDelayCertificateFormJSON2Apex) System.JSON.deserialize(
      json,
      FlightDelayCertificateFormJSON2Apex.class
    );
  }
}
