public without sharing class Segment extends AbstractSObjectWrapper implements Comparable {
  public Segment__c underlyingSObject { get; private set; }

  public Id bookingId;
  public Id flightId;

  public Decimal baggageQuantity;
  public String bookingClass;
  public String checkInStatus;
  public String fareBasis;
  public Decimal farePrice;
  public String identifier;
  public Boolean isBoarded = false; // TODO: see if this can be removed
  public String seat;
  public String segmentStatus;
  public String segmentStatusCode;
  public String serviceClass;
  public String specialServiceRequests;
  public String ticketNumber;
  public String ticketType;
  public String tripType;

  public Flight flight;

  @TestVisible
  private List<SegmentEvent> events;

  public enum Status {
    Unknown,
    CallToConfirm,
    Cancelled,
    Confirmed,
    SpaceAvailable,
    Suspended,
    Unconfirmed,
    Waitlisted
  }

  public void setEvents(List<SegmentEvent> events) {
    if (events != null) {
      events.sort();
    }
    this.events = events;
  }

  public List<SegmentEvent> getEvents() {
    return this.events;
  }

  public class UnsupportedException extends Exception {
  }
  public class CancelledFromConfirmedException extends Exception {
  }

  private Segment() {
    this.underlyingSObject = new Segment__c();
  }

  public Segment(Segment__c s) {
    super(s);
    this.underlyingSObject = s;

    this.bookingId = s.Booking__c;
    this.flightId = s.Flight__c;
    this.baggageQuantity = s.Baggage_Quantity__c;
    this.bookingClass = s.Booking_Class__c;
    this.checkInStatus = s.Check_In_Status__c;
    this.fareBasis = s.Fare_Basis__c;
    this.farePrice = s.Fare_Price__c;
    this.identifier = s.Identifier__c;
    this.isBoarded = s.Is_Boarded__c;
    this.seat = s.Seat__c;
    this.segmentStatus = s.Segment_Status__c;
    this.segmentStatusCode = s.Segment_Status_Code__c;
    this.serviceClass = s.Service_Class__c;
    this.specialServiceRequests = s.Special_Service_Requests__c;
    this.ticketNumber = s.Ticket_Number__c;
    this.ticketType = s.Ticket_Type__c;
    this.tripType = s.Trip_Type__c;

    if (s.Flight__r != null) {
      this.flight = new Flight(s.Flight__r);
    }
  }

  public override void updateSObjectFields() {
    this.underlyingSObject.Baggage_Quantity__c = this.baggageQuantity;
    this.underlyingSObject.Booking__c = this.bookingId;
    this.underlyingSObject.Booking_Class__c = this.bookingClass;
    this.underlyingSObject.Check_In_Status__c = this.checkInStatus;
    this.underlyingSObject.Fare_Basis__c = this.fareBasis;
    this.underlyingSObject.Fare_Price__c = this.farePrice;
    this.underlyingSObject.Flight__c = this.flightId;
    this.underlyingSObject.Identifier__c = this.identifier;
    this.underlyingSObject.Is_Boarded__c = this.isBoarded;
    this.underlyingSObject.Seat__c = this.seat;
    this.underlyingSObject.Segment_Status__c = this.segmentStatus;
    this.underlyingSObject.Segment_Status_Code__c = this.segmentStatusCode;
    this.underlyingSObject.Service_Class__c = this.serviceClass;
    this.underlyingSObject.Special_Service_Requests__c = this.specialServiceRequests;
    this.underlyingSObject.Ticket_Number__c = this.ticketNumber;
    this.underlyingSObject.Ticket_Type__c = this.ticketType;
    this.underlyingSObject.Trip_Type__c = this.tripType;
  }

  public Integer compareTo(Object other) {
    Segment otherSegment = (Segment) other;

    Integer toReturn = 0;

    if (other == null) {
      return 1;
    }

    if (this.flight == null || otherSegment.flight == null) {
      return 0;
    }

    if (
      this.flight.scheduledDepartureTime >
      otherSegment.flight.scheduledDepartureTime
    ) {
      return 1;
    } else if (
      this.flight.scheduledDepartureTime <
      otherSegment.flight.scheduledDepartureTime
    ) {
      return -1;
    } else {
      return 0;
    }
  }

  /**
   * Gets the segment status at a specific time.
   * Currently only supports Confirmed, Cancelled and Unknown
   */
  public Status getStatus(Datetime theTime) {
    U.verifyNotNull(this.events);

    Status currentStatus = Status.Unknown;
    for (SegmentEvent se : events) {
      if (se.updateDate > theTime) {
        break;
      }

      switch on se.newStatus {
        when C_HK, C_TK {
          // Holds confirmed
          // Schedule Change. Advise passenger of new scheduled times.
          currentStatus = Status.Confirmed;
        }
        when C_UN {
          // Unable - no flight
          currentStatus = Status.Unconfirmed;
        }
        when C_XX {
          // Cancel segment
          currentStatus = Status.Cancelled;
        }
        when C_UC, C_US, C_UU {
          // Unable to confirm or waitlist
          // Unable to sell
          // Unable to confirm. Waitlist requested'
          throw new UnsupportedException(
            'Segment has unsupported "Unable"-status'
          );
        }
        when C_GF, C_GK, C_GL, C_GN, C_GO {
          // Guaranteed/Merged. Also used in 1V as Passive - Group confirmed
          throw new UnsupportedException('Group segments are not supported');
        }
        when C_HX, C_XK {
          // Cancel confirm hold
          // Cancel seg with change
          // Group statuses
          throw new UnsupportedException('Segment has an unsupported status');
        }
      }
    }

    return currentStatus;
  }

  /**
   * (Unconfirmed = unable)
   */
  public SegmentEvent getUnconfirmedEvent() {
    U.verifyNotNull(this.events);

    SegmentEvent unableEvent;
    Datetime unableTime;
    for (SegmentEvent se : events) {
      if (se.newStatus == SegmentEvent.StatusCode.C_UN) {
        if (
          unableEvent != null &&
          se.previousStatus != SegmentEvent.StatusCode.C_UN &&
          unableTime != se.updateDate
        ) {
          // Sometimes the event is duplicated, so ignore the double UN in that case
          throw new UnsupportedException('More than one unconfirmed time.');
        }

        // Store the first time when the segment was "unable"
        if (unableEvent == null) {
          unableEvent = se;
          unableTime = se.updateDate;
        }
      }
    }

    return unableEvent;
  }

  public SegmentEvent getRemovedEvent() {
    U.verifyNotNull(this.events);

    SegmentEvent removedEvent;
    Datetime removedTime;
    for (SegmentEvent se : events) {
      if (se.operationType == SegmentEvent.OperationType.C_X) {
        if (removedEvent != null && removedTime != se.updateDate) {
          throw new UnsupportedException('More than one removal time.');
        }
        removedEvent = se;
        removedTime = se.updateDate;
      }
    }
    return removedEvent;
  }

  public Boolean hasBeenReinstated() {
    U.verifyNotNull(this.events);

    Status currentStatus = Status.Unknown;
    for (SegmentEvent se : events) {
      switch on se.newStatus {
        when C_HK, C_TK {
          if (
            currentStatus == Status.Unconfirmed ||
            currentStatus == Status.Cancelled
          ) {
            return true;
          }
        }
        when C_UN {
          // Unable - no flight
          currentStatus = Status.Unconfirmed;
        }
        when C_XX {
          // Cancel segment
          currentStatus = Status.Cancelled;
        }
      }
    }

    return false;
  }
}
