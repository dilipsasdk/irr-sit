public with sharing class EDWReservation extends Reservation {
  //Used by EDW when actual timestamp data is not available
  private Map<String, FetchEDWBookingResponse.TicketInfo> tickets { get; set; }
  private static final Map<String, String> ACCEPTANCE_STATUS_TO_PICKLIST_VALUE = new Map<String, String>{
    'CAC' => 'Accepted',
    'CNA' => 'NotAccepted',
    'CST' => 'StandBy',
    'CRJ' => 'Rejected'
  };
  private static final Long EDW_NULL_TIMESTAMP = -2208988800000L;

  public EDWReservation(FetchEDWBookingResponse.Reservation edwReservation) {
    super();
    this.tickets = this.addTicketInformationFromSourceData(
      edwReservation.ticketInfoList.ticketInfo
    );
    this.booking = this.constructBookingFromSourceData(edwReservation);
    this.flights = this.constructFlightsFromSourceData(
      edwReservation.irregularityList.irregularity
    );
    this.booking.flights = new Set<Flight>(this.flights.values());
    this.booking.passengers = this.constructPassengersFromSourceData(
      edwReservation.passengerList.passenger
    );
    this.booking.segments = this.constructSegmentsFromSourceData(
      edwReservation.segmentList.segment
    );
  }

  public override Booking constructBookingFromSourceData(Object sourceData) {
    FetchEDWBookingResponse.Reservation bookingData = (FetchEDWBookingResponse.Reservation) sourceData;
    String bookingIdentifier = String.format(
      '{0}-{1}',
      new List<Object>{
        bookingData.reservationNumber,
        Datetime.newInstance(bookingData.createdDate).formatGmt('yyyyMMdd')
      }
    );
    //create booking
    Booking b = new Booking(new Booking__c(Name = bookingIdentifier));
    b.bookingReference = bookingData.reservationNumber;
    b.tedsIdentifier = bookingIdentifier;
    //TODO Ask SEIP to fix the Json response to have these separately
    if (bookingData.segmentList?.segment.size() > 0) {
      b.createdAtTravelOfficeId = bookingData.segmentList.segment[0].offCd;
      b.isStaffBooking = bookingData.segmentList.segment[0].staffPNR == 'Y';
    }
    return b;
  }

  public override List<Passenger> constructPassengersFromSourceData(
    List<Object> sourceData
  ) {
    List<Passenger> toReturn = new List<Passenger>();
    for (
      FetchEDWBookingResponse.Passenger passenger : (List<FetchEDWBookingResponse.Passenger>) sourceData
    ) {
      Passenger p = new Passenger(new Passenger__c(Name = passenger.surName));
      p.firstName = passenger.firstName;
      p.lastName = passenger.surName;
      p.euroBonusNumber = String.valueOf(passenger.ebNumber);
      p.email = StringUtils.isEmailAddress(passenger.email)
        ? passenger.email
        : '';
      p.phone = String.valueOf(passenger.mobile);
      p.identifier = 'PT' + passenger.passengerTattoo;
      toReturn.add(p);
    }
    return toReturn;
  }

  public override List<Segment> constructSegmentsFromSourceData(
    List<Object> sourceData
  ) {
    Map<String, List<Segment>> flightIdToSegments = new Map<String, List<Segment>>();
    Map<String, Map<String, List<SegmentEvent>>> segmentIdToEventsByPassenger = constructSegmentEventsFromSourceData(
      sourceData
    );
    Set<String> processedFlightIds = new Set<String>();
    List<Segment> toReturn = new List<Segment>();
    for (
      FetchEDWBookingResponse.Segment segment : (List<FetchEDWBookingResponse.Segment>) sourceData
    ) {
      if (segment.isLatest == 1 || segment.segStatus == 'SCHED') {
        String segmentFlightId = String.format(
          '{0}{1}-{2}-{3}-{4}',
          new List<Object>{
            segment.fltAirlCd,
            segment.fltNm,
            Datetime.newInstance(segment.depDte).formatGmt('yyyyMMdd'),
            segment.stnFrCd,
            segment.stnToCd
          }
        );
        if (processedFlightIds.contains(segmentFlightId)) {
          continue;
        }
        for (Passenger passenger : this.booking.passengers) {
          Segment s = new Segment(new Segment__c(Name = segmentFlightId));
          s.identifier = String.format(
            'ST{0}{1}',
            new List<Object>{ segment.segTattoo, passenger.identifier }
          );
          s.bookingClass = segment.oprBkgCl;
          s.segmentStatusCode = segment.segStatus;
          s.serviceClass = segment.oprSvcCl;
          s.flight = this.flights.get(segmentFlightId);
          s.setEvents(
            segmentIdToEventsByPassenger.get(passenger.identifier)
              ?.get(segmentFlightId)
          );
          FetchEDWBookingResponse.TicketInfo ticketForSegment = this.tickets.get(
            s.identifier
          );
          if (ticketForSegment != null) {
            s.ticketNumber = String.format(
              '{0}-{1}',
              new List<Object>{
                ticketForSegment.tktAirlCd,
                ticketForSegment.tktNo
              }
            );
            s.seat = ticketForSegment.seatNo;
            s.baggageQuantity = ticketForSegment.bagCnt;
            s.fareBasis = ticketForSegment.fareBasis;
            s.isBoarded = ticketForSegment.boardingInd == 'Y';
            s.checkInStatus = ACCEPTANCE_STATUS_TO_PICKLIST_VALUE.containsKey(
                ticketForSegment.acceptanceSts
              )
              ? ACCEPTANCE_STATUS_TO_PICKLIST_VALUE.get(
                  ticketForSegment.acceptanceSts
                )
              : null;
          }
          toReturn.add(s);
        }
        processedFlightIds.add(segmentFlightId);
      }
    }
    return toReturn;
  }

  private Map<String, Map<String, List<SegmentEvent>>> constructSegmentEventsFromSourceData(
    List<Object> sourceData
  ) {
    List<SegmentEvent> processedEvents = new List<SegmentEvent>();
    Map<String, Map<String, List<SegmentEvent>>> segmentIdToEventsPerPassenger = new Map<String, Map<String, List<SegmentEvent>>>();
    for (
      FetchEDWBookingResponse.Segment segment : (List<FetchEDWBookingResponse.Segment>) sourceData
    ) {
      String segmentFlightId = String.format(
        '{0}{1}-{2}-{3}-{4}',
        new List<Object>{
          segment.fltAirlCd.trim(),
          segment.fltNm,
          Datetime.newInstance(segment.depDte).formatGmt('yyyyMMdd'),
          segment.stnFrCd,
          segment.stnToCd
        }
      );
      for (Passenger passenger : this.booking.passengers) {
        if (!segmentIdToEventsPerPassenger.containsKey(passenger.identifier)) {
          segmentIdToEventsPerPassenger.put(
            passenger.identifier,
            new Map<String, List<SegmentEvent>>()
          );
        }
        SegmentEvent se = new SegmentEvent(new Segment_Event__c());
        se.operationType = SegmentEvent.getOperationTypeFromPicklistValue(
          segment.recordOprType.replace('D', '').trim()
        );
        se.newStatus = SegmentEvent.getStatusCodeFromPicklistValue(
          segment.actionCd?.trim()
        );
        se.previousStatus = SegmentEvent.getStatusCodeFromPicklistValue(
          segment.prevActionCd?.trim()
        );
        se.officeCode = segment.officeUpdating;
        se.updateDate = DateUtils.convertTimestampToDatetime(
          U.getOr(EDW_NULL_TIMESTAMP, segment.resUpdTms),
          EDW_NULL_TIMESTAMP
        );
        se.updateNumber = segment.resUpdateNo;
        processedEvents.add(se);
        if (
          !segmentIdToEventsPerPassenger.get(passenger.identifier)
            .containsKey(segmentFlightId)
        ) {
          segmentIdToEventsPerPassenger.get(passenger.identifier)
            .put(segmentFlightId, new List<SegmentEvent>());
        }
        segmentIdToEventsPerPassenger.get(passenger.identifier)
          .get(segmentFlightId)
          .add(se);
      }
    }
    return segmentIdToEventsPerPassenger;
  }

  private Map<String, FetchEDWBookingResponse.TicketInfo> addTicketInformationFromSourceData(
    List<Object> sourceData
  ) {
    Map<String, FetchEDWBookingResponse.TicketInfo> segmentIdentifierToTicketInfo = new Map<String, FetchEDWBookingResponse.TicketInfo>();
    for (
      FetchEDWBookingResponse.TicketInfo ticket : (List<FetchEDWBookingResponse.TicketInfo>) sourceData
    ) {
      String ticketIdentifier = String.format(
        'ST{0}PT{1}',
        new List<Object>{ ticket.segTattoo, ticket.passengerTattoo }
      );
      if (!segmentIdentifierToTicketInfo.containsKey(ticketIdentifier)) {
        segmentIdentifierToTicketInfo.put(ticketIdentifier, ticket);
      }
    }
    return segmentIdentifierToTicketInfo;
  }

  public override Map<String, Flight> constructFlightsFromSourceData(
    List<Object> sourceData
  ) {
    Map<String, Flight> flightIdToRecord = new Map<String, Flight>();
    Map<String, List<FlightIrregularity>> flightIdToIrregularities = constructFlightIrregularitiesFromSourceData(
      sourceData
    );
    for (
      FetchEDWBookingResponse.Irregularity irr : (List<FetchEDWBookingResponse.Irregularity>) sourceData
    ) {
      // The irr.depDte is in local time, however, there always exists data for it.
      // We should try to construct the tedsIdentifier from stdTms when it exists.
      // TODO: ask EDW to convert the depDte to UTC
      Long depTimestamp = irr.stdTms == EDW_NULL_TIMESTAMP
        ? irr.depDte
        : irr.stdTms;
      Datetime identifierDate = DateUtils.convertTimestampToDatetime(
        U.getOr(EDW_NULL_TIMESTAMP, depTimestamp),
        EDW_NULL_TIMESTAMP
      );
      if (identifierDate == null) {
        continue; // Invalid data, skip
      }

      String irrFlightId = String.format(
        '{0}-{1}-{2}-{3}',
        new List<Object>{
          irr.fltId.deleteWhitespace(),
          identifierDate.formatGmt('yyyyMMdd'),
          irr.stnFrCd,
          irr.stnToCd
        }
      );
      if (flightIdToRecord.get(irrFlightId) != null) {
        continue;
      }
      //The input data contains different data based on if flight belongs to SK or other carrier
      String flightStatus = 'unknown';
      String arrivalStatus = 'unknown';
      String departureStatus = 'unknown';
      switch on irr.status {
        when 'DEPARTURE DELAYED' {
          flightStatus = 'delayed';
          arrivalStatus = 'ontime';
          departureStatus = 'delayed';
        }
        when 'ARRIVAL DELAYED' {
          flightStatus = 'delayed';
          arrivalStatus = 'delayed';
          departureStatus = 'ontime';
        }
        when 'DEPARTUE AND ARRIVAL DELAYED' {
          flightStatus = 'delayed';
          arrivalStatus = 'delayed';
          departureStatus = 'delayed';
        }
        when 'CANCELLED' {
          flightStatus = 'cancelled';
          arrivalStatus = 'cancelled';
          departureStatus = 'cancelled';
        }
        when 'ON TIME' {
          flightStatus = 'ontime';
          arrivalStatus = 'ontime';
          departureStatus = 'ontime';
        }
        when else {
          flightStatus = 'unknown';
          arrivalStatus = 'unknown';
          departureStatus = 'unknown';
        }
      }
      Flight f = new Flight(new Flight__c(Name = irrFlightId));
      f.tedsIdentifier = irrFlightId;
      f.aircraftRegistration = irr.aircraftRegistration;
      f.arrivalAirport = irr.stnToCd;
      f.arrivalDelayedMinutes = irr.arrivalDelayMins;
      f.arrivalStatus = Flight.getStatusFromPicklistValue(arrivalStatus);
      f.departureAirport = irr.stnFrCd;
      f.departureDelayedMinutes = irr.depDelayMins;
      f.departureStatus = Flight.getStatusFromPicklistValue(departureStatus);
      f.actualArrivalTime = DateUtils.convertTimestampToDatetime(
        U.getOr(EDW_NULL_TIMESTAMP, irr.ataTms),
        EDW_NULL_TIMESTAMP
      );
      f.actualDepartureTime = DateUtils.convertTimestampToDatetime(
        U.getOr(EDW_NULL_TIMESTAMP, irr.atdTms),
        EDW_NULL_TIMESTAMP
      );
      f.estimatedArrivalTime = DateUtils.convertTimestampToDatetime(
        U.getOr(EDW_NULL_TIMESTAMP, irr.etaTms),
        EDW_NULL_TIMESTAMP
      );
      f.estimatedDepartureTime = DateUtils.convertTimestampToDatetime(
        U.getOr(EDW_NULL_TIMESTAMP, irr.etdTms),
        EDW_NULL_TIMESTAMP
      );
      f.scheduledArrivalTime = DateUtils.convertTimestampToDatetime(
        U.getOr(EDW_NULL_TIMESTAMP, irr.staTms),
        EDW_NULL_TIMESTAMP
      );
      f.scheduledDepartureTime = DateUtils.convertTimestampToDatetime(
        U.getOr(EDW_NULL_TIMESTAMP, irr.stdTms),
        EDW_NULL_TIMESTAMP
      );
      f.irregularities = flightIdToIrregularities.get(irrFlightId);
      flightIdToRecord.put(irrFlightId, f);
    }
    return flightIdToRecord;
  }

  private Map<String, List<FlightIrregularity>> constructFlightIrregularitiesFromSourceData(
    List<Object> sourceData
  ) {
    Map<String, List<FlightIrregularity>> flightIdToIrregularities = new Map<String, List<FlightIrregularity>>();
    for (
      FetchEDWBookingResponse.Irregularity irr : (List<FetchEDWBookingResponse.Irregularity>) sourceData
    ) {
      Boolean cancelledOrDelayed =
        irr.status.contains('DELAYED') || irr.fltStatus == 'X';
      if (!cancelledOrDelayed) {
        continue;
      }

      String irrFlightId = String.format(
        '{0}-{1}-{2}-{3}',
        new List<Object>{
          irr.fltId.deleteWhitespace(),
          Datetime.newInstance(irr.depDte).formatGmt('yyyyMMdd'),
          irr.stnFrCd,
          irr.stnToCd
        }
      );
      FlightIrregularity fi = new FlightIrregularity(
        new FlightIrregularities__c()
      );
      fi.cancellationTime = DateUtils.convertTimestampToDatetime(
        U.getOr(EDW_NULL_TIMESTAMP, irr.cnlEventDts),
        EDW_NULL_TIMESTAMP
      );
      fi.code = irr.fltStatus == 'X' ? irr.cnlRsnCd : irr.delayRsnCd;
      FlightIrregularity.EU261Eligibility eligibleForEU261;
      if (!FlightIrregularity.codeToSASIsResponsible.containsKey(fi.code)) {
        eligibleForEU261 = FlightIrregularity.EU261Eligibility.Tentative;
      } else if (FlightIrregularity.codeToSASIsResponsible.get(fi.code)) {
        eligibleForEU261 = FlightIrregularity.EU261Eligibility.Yes;
      } else {
        eligibleForEU261 = FlightIrregularity.EU261Eligibility.No;
      }
      fi.eligibleForEU261 = eligibleForEU261;
      fi.durationMinutes = Decimal.valueOf(irr.duration);
      fi.nameC = '';
      String reasonText = irr.fltStatus == 'X'
        ? irr.cnlSpplInfo
        : irr.delayRsnText;
      if (reasonText?.length() > 2000) {
        reasonText = reasonText.substring(0, 2000);
      }
      fi.reason = reasonText;
      fi.type = irr.status;
      if (!flightIdToIrregularities.containsKey(irrFlightId)) {
        flightIdToIrregularities.put(
          irrFlightId,
          new List<FlightIrregularity>()
        );
      }
      flightIdToIrregularities.get(irrFlightId).add(fi);
    }
    return flightIdToIrregularities;
  }
}
