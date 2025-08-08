public without sharing class FlightDelayCertificateRequests extends ApplicationDomain {
  public FlightDelayCertificateRequests(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<Flight_Delay_Certificate_Request__c>) Records;
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new FlightDelayCertificateRequests(records);
    }
  }

  public static FlightDelayCertificateRequests newInstance(
    List<Flight_Delay_Certificate_Request__c> sObjectList
  ) {
    return (FlightDelayCertificateRequests) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }

  public List<Flight_Delay_Certificate_Request__c> instanceRecords;
  public Map<String, Blob> generatedFlightDelayCertificates = new Map<String, Blob>();

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    updateBookingOnRelatedCase(
      (Map<Id, Flight_Delay_Certificate_Request__c>) existingRecords
    );
  }

  public class FlightDelayCertificateException extends Exception {
  }

  public Blob generateFlightDelayCertificate(Id bookingId) {
    if (instanceRecords.size() != 1) {
      //TODO Should this return something else?
      return null;
    }
    Flight_Delay_Certificate_Request__c request = instanceRecords[0];
    PageReference fdcPage = new PageReference(
      '/apex/flightdelaycertificatepage'
    );
    fdcPage.getParameters().put('bookingId', bookingId);
    fdcPage.getParameters().put('passengerName', request.Contact_Full_Name__c);
    fdcPage.getParameters().put('enteredFlight', request.Flight_Number__c);
    fdcPage.getParameters().put('caseNumber', request.Case__r.CaseNumber);
    fdcPage.getParameters()
      .put('bookingReference', request.Booking_Reference__c);
    fdcPage.setRedirect(false);
    Blob fdcPageAsPdf;
    try {
      if (System.Test.isRunningTest()) {
        fdcPageAsPdf = Blob.valueOf('test');
      } else {
        fdcPageAsPdf = fdcPage.getContentAsPDF();
      }
    } catch (Exception e) {
      throw new FlightDelayCertificateException(
        'Could not covert PageReference to PDF. ' + e.getMessage()
      );
    }
    return fdcPageAsPdf;
  }

  public void updateBookingOnRelatedCase(
    Map<Id, Flight_Delay_Certificate_Request__c> oldFdcRequests
  ) {
    for (Flight_Delay_Certificate_Request__c req : instanceRecords) {
      Flight_Delay_Certificate_Request__c fdcrBeforeUpdate = oldFdcRequests.get(
        req.Id
      );
      if (req.Booking_Reference__c != fdcrBeforeUpdate.Booking_Reference__c) {
        System.enqueueJob(
          new BookingService.AddBookingToCaseAsync(
            req.Case__c,
            req.Booking_Reference__c
          )
        );
      }
    }
  }
}
