@IsTest
public with sharing class TestSegmentFactory {
  public enum History {
    DEFAULTCONFIRMED,
    DEFAULTCANCELLATION,
    DEFAULTREPLACEMENT,
    REMOVEDNOTCANCELLED,
    DOUBLEUNCONFIRMED,
    UNABLETOCONFIRM,
    GROUPBOOKING,
    FULLHISTORY
  } // TODO Rename

  public class SegmentsInfo {
    Flight f;
    Datetime timeAddedToBooking;
    Datetime timeRemovedFromBooking;
    History history;

    public SegmentsInfo(
      Flight f,
      Datetime timeAddedToBooking,
      Datetime timeRemovedFromBooking
    ) {
      this.f = f;
      this.timeAddedToBooking = timeAddedToBooking;
      this.timeRemovedFromBooking = timeRemovedFromBooking;
    }

    public SegmentsInfo(
      Flight f,
      Datetime timeAddedToBooking,
      Datetime timeRemovedFromBooking,
      History history
    ) {
      this.f = f;
      this.timeAddedToBooking = timeAddedToBooking;
      this.timeRemovedFromBooking = timeRemovedFromBooking;
      this.history = history;
    }
  }

  public static Segment createFromBookingFlightPassenger(
    Booking b,
    Flight f,
    Passenger p
  ) {
    Segment s = new Segment(new Segment__c());
    s.flight = f;
    s.flightId = f.id;
    s.id = fflib_IDGenerator.generate(Segment__c.getSObjectType());

    s.baggageQuantity = 0;
    s.bookingClass = 'A';
    s.checkInStatus = '';
    s.fareBasis = 'ABCDE';
    s.farePrice = 200;
    s.identifier = 'ST1';
    s.isBoarded = true;
    s.seat = '1A';
    s.segmentStatus = 'Accepted';
    s.segmentStatusCode = 'HK';
    s.serviceClass = 'A';
    s.specialServiceRequests = '';
    s.ticketNumber = '1234567890';
    s.ticketType = '';

    s.tripType = 'Outbound';

    for (FlightIrregularity fi : s.flight.irregularities) {
      if (fi.isCancellation()) {
        s.tripType = 'Cancelled';
      }
    }

    return s;
  }

  public static List<Segment> createFromBookingFlights(
    Booking b,
    List<SegmentsInfo> segmentsInfos
  ) {
    List<Segment> segments = new List<Segment>{};
    for (SegmentsInfo si : segmentsInfos) {
      for (Passenger p : b.passengers) {
        Segment s = createFromBookingFlightPassenger(b, si.f, p);
        List<SegmentEvent> events = createEvents(
          s,
          si.timeAddedToBooking,
          si.timeRemovedFromBooking,
          si.history
        );
        s.setEvents(events);
        segments.add(s);
      }
    }
    return segments;
  }

  public static List<SegmentEvent> createEvents(
    Segment s,
    Datetime timeAdded,
    Datetime timeCancelled,
    History segmentHistory
  ) {
    List<SegmentEvent> toReturn;
    if (segmentHistory == null) {
      if (s.tripType == 'Cancelled') {
        toReturn = TestSegmentEventFactory.createForDefaultCancellation(
          s,
          timeAdded,
          timeCancelled
        );
      } else {
        toReturn = TestSegmentEventFactory.createForDefaultConfirmed(
          s,
          timeAdded
        );
      }
    } else {
      switch on segmentHistory {
        when DEFAULTCANCELLATION {
          toReturn = TestSegmentEventFactory.createForDefaultCancellation(
            s,
            timeAdded,
            timeCancelled
          );
        }
        when DEFAULTREPLACEMENT {
          toReturn = TestSegmentEventFactory.createForDefaultReplacement(
            s,
            timeAdded
          );
        }
        when REMOVEDNOTCANCELLED {
          toReturn = TestSegmentEventFactory.createForRemovedNotCancelled(
            s,
            timeAdded,
            timeCancelled
          );
        }
        when DOUBLEUNCONFIRMED {
          toReturn = TestSegmentEventFactory.createForDoubleUnconfirmed(
            s,
            timeAdded,
            timeCancelled
          );
        }
        when UNABLETOCONFIRM {
          toReturn = TestSegmentEventFactory.createWithUnableToConfirm(
            s,
            timeAdded
          );
        }
        when GROUPBOOKING {
          toReturn = TestSegmentEventFactory.createGroup(s, timeAdded);
        }
        when else {
          toReturn = TestSegmentEventFactory.createForDefaultConfirmed(
            s,
            timeAdded
          );
        }
      }
    }

    return toReturn;
  }
}
