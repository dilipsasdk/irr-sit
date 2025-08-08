
/**
 * Same logic expect response isCancelled field is set to true.
 */
@isTest
global class TEDSBookingQuerySuccessAnotherMock implements HttpCalloutMock {
  String responseBody = '[{"id": "{bookingReference}-20201126","reference": "{bookingReference}","type": "RoundTrip","isCancelled": true,"codsId": "TEST1234","travelAdmin": {"codsId": ""},"audit": {"created": {"officeId": "TEST1234","at": "2020-11-26T04:15:00Z"},"updated": {"officeId": "TEST1234","at": "2021-02-19T22:25:00Z"}},"passengers": [{"id": "PT2","title": "MR","firstName": "TEST","lastName": "TESTSSON","contact": {"phone": [{"type": "APH","number": ""},{"type": "APM","number": ""},{"type": "APU","number": ""},{"type": "APH","number": ""},{"type": "APM","number": ""},{"type": "APU","number": ""}],"email": [{"type": "APE","address": "TEST@EXAMPLE.COM"},{"type": "APE","address": "TEST@EXAMPLE.COM"}]},"frequentTraveler": {"euroBonus": [{"segmentIds": [],"carrier": "SK","tier": "EBB","number": "{euroBonusNumber}"}],"other": []},"specialServiceRequests": [],"segments": [{"segmentId": "ST1","isBoarded": false,"ticket": {"number": "117-TEST123456","type": "ETKT"},"baggage": {"quantity": {"allowed": 1,"extra": 0}},"fare": {"basis": "OSERSM"}},{"segmentId": "ST2","isBoarded": false,"ticket": {"number": "117-TEST123456","type": "ETKT"},"baggage": {"quantity": {"allowed": 1,"extra": 0}},"fare": {"basis": "TSERSM"}}]}],"trips": [{"type": "Outbound","segments": [{"id": "ST1","statusCode": "HK","status": "Confirmed","transportationType": "Flight","flight": {"id": "SK2569-20210410-ARN-CPH","operatingId": "SK2569-20210410-ARN-CPH","operatingCarrier": "SK","operatingFlightNumber": "2569","marketingCarrier": "SK","marketingFlightNumber": "2569","departure": {"station": "ARN","scheduledTime": {"utc": "2021-04-10T07:00:00Z","local": "2021-04-10T09:00:00"},"terminal": "5"},"arrival": {"station": "CPH","scheduledTime": {"utc": "2021-04-10T08:20:00Z","local": "2021-04-10T10:20:00"},"terminal": "3"}},"bookingClass": "O","serviceClass": "M"}]},{"type": "Inbound","segments": [{"id": "ST2","statusCode": "HK","status": "Confirmed","transportationType": "Flight","flight": {"id": "SK0402-20210420-CPH-ARN","operatingId": "SK0402-20210420-CPH-ARN","operatingCarrier": "SK","operatingFlightNumber": "0402","marketingCarrier": "SK","marketingFlightNumber": "0402","departure": {"station": "CPH","scheduledTime": {"utc": "2021-04-20T05:15:00Z","local": "2021-04-20T07:15:00"},"terminal": "3"},"arrival": {"station": "ARN","scheduledTime": {"utc": "2021-04-20T06:30:00Z","local": "2021-04-20T08:30:00"},"terminal": "5"}},"bookingClass": "T","serviceClass": "M"}]}]}]';

  global HttpResponse respond(HttpRequest req) {
    String endpoint = req.getEndpoint();

    String reference = 'TEST21';
    String euroBonusNumber = endpoint.substringBetween('euroBonusNumber=', '&'); // grab EuroBonus queryparam to insert in response
    if (euroBonusNumber == null || euroBonusNumber.length() == 0) {
      // if not found, check if it's the last one
      euroBonusNumber = endpoint.substringAfter('euroBonusNumber=');
      if (euroBonusNumber == null || euroBonusNumber.length() == 0) {
        // doesn't seem to exist
        euroBonusNumber = 'TEST987654';
      }
    }

    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setBody(
      responseBody.replace('{bookingReference}', reference)
        .replace('{euroBonusNumber}', euroBonusNumber)
    );
    res.setStatusCode(200);
    return res;
  }
}
