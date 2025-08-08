// Tests for EU261Claim.evaluate()
@TestVisible
@IsTest
private class EU261Claim_Test_Old {
  // Needs to be dynamically set as the time limit checks claim created date (which moves)
  private static Datetime departure = Datetime.now().addDays(-50);

  private static EU261Service.Config config = new EU261Service.Config(
    new EU261_Automation_Configuration__mdt(
      Automatic_Rejection__c = false,
      Delay_Automation__c = true,
      Cancellation_Automation__c = true,
      Automatic_Settlement__c = false,
      Claim_Expense_Max_Amount__c = 0,
      Expense_Limit_Accommodation__c = 0,
      Expense_Limit_Food__c = 0,
      Expense_Limit_Phone_Calls__c = 0,
      Expense_Limit_Transportation__c = 0,
      Percentage_Sent_to_Control__c = 0
    )
  );

  private class BookingClaim {
    public Booking b;
    public Claim c;

    public BookingClaim(Booking b, Claim c) {
      this.b = b;
      this.c = c;
    }
  }

  private static BookingClaim getDefaultDelayBookingClaim() {
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    List<Flight> flights = new List<Flight>{ f1 };

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createDefaultDelay(f1)
    };
    f1.irregularities = fis;
    f1.arrivalDelayedMinutes = 180;
    f1.actualArrivalTime = f1.scheduledArrivalTime.addMinutes(180);

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightDelayCompensation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);
    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      null
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1
    };

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    return new BookingClaim(b, c);
  }

  private static BookingClaim getHiddenCancellationBookingClaim() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.c.type = Claim.Type.FlightDelayCompensation;
    Set<Flight> newFlights = new Set<Flight>();
    for (Flight f : bc.b.flights) {
      if (f.getFlightNumber() == 'SK0001') {
        f.irregularities = new List<FlightIrregularity>();
      }
      newFlights.add(f);
    }
    bc.b.flights = newFlights;

    return bc;
  }

  private static BookingClaim getDefaultMissedConnectionBookingClaim() {
    // First flight is delayed leading to the passenger missing their next flight, ultimately leading to a 4 hour delay
    Datetime connectingFlightDeparture = departure.addHours(3);
    Datetime connectingFlightDepartureRemoval = departure.addHours(4);
    Datetime connectingFlightReplacementDeparture = departure.addHours(7);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL'); // 2h flight
    Flight f2 = TestFlightFactory.create(
      'SK0002',
      connectingFlightDeparture,
      'HEL',
      'CPH'
    );
    Flight f3 = TestFlightFactory.create(
      'SK0003',
      connectingFlightReplacementDeparture,
      'HEL',
      'CPH'
    );
    List<Flight> flights = new List<Flight>{ f1, f2, f3 };

    FlightIrregularity delay = TestIrregularityFactory.createDefaultDelay(f1);
    delay.durationMinutes = 75;
    List<FlightIrregularity> fis = new List<FlightIrregularity>{ delay };
    f1.irregularities = fis;
    f1.arrivalDelayedMinutes = 75;
    f1.actualArrivalTime = f1.scheduledArrivalTime.addMinutes(75);

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightDelayCompensation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);
    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      null
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      departure.addDays(-60),
      connectingFlightDepartureRemoval,
      TestSegmentFactory.History.DEFAULTCANCELLATION
    );
    TestSegmentFactory.SegmentsInfo sInfo3 = new TestSegmentFactory.SegmentsInfo(
      f3,
      connectingFlightDepartureRemoval,
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2,
      sInfo3
    };

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    return new BookingClaim(b, c);
  }

  private static BookingClaim getMissedConnectionWhereDelayResultedInEarlyUNBookingClaim() {
    // First flight is delayed leading to the passenger missing their next flight, ultimately leading to a 4 hour delay
    Datetime connectingFlightDeparture = departure.addHours(3);
    Datetime connectingFlightDepartureRemoval = departure.addHours(-4);
    Datetime connectingFlightReplacementDeparture = departure.addHours(7);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL'); // 2h flight
    Flight f2 = TestFlightFactory.create(
      'SK0002',
      connectingFlightDeparture,
      'HEL',
      'CPH'
    );
    Flight f3 = TestFlightFactory.create(
      'SK0003',
      connectingFlightReplacementDeparture,
      'HEL',
      'CPH'
    );
    List<Flight> flights = new List<Flight>{ f1, f2, f3 };

    FlightIrregularity delay = TestIrregularityFactory.createDefaultDelay(f1);
    delay.durationMinutes = 75;
    List<FlightIrregularity> fis = new List<FlightIrregularity>{ delay };
    f1.irregularities = fis;
    f1.arrivalDelayedMinutes = 75;
    f1.actualArrivalTime = f1.scheduledArrivalTime.addMinutes(75);

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightDelayCompensation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);
    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      null
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      departure.addDays(-60),
      connectingFlightDepartureRemoval,
      TestSegmentFactory.History.DEFAULTCANCELLATION
    );
    TestSegmentFactory.SegmentsInfo sInfo3 = new TestSegmentFactory.SegmentsInfo(
      f3,
      connectingFlightDepartureRemoval,
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2,
      sInfo3
    };

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    return new BookingClaim(b, c);
  }

  private static BookingClaim getDefaultMissedConnectionBookingClaimWithoutReplacement() {
    // First flight is delayed leading to the passenger missing their next flight, ultimately leading to a 4 hour delay
    Datetime connectingFlightDeparture = departure.addHours(3);
    Datetime connectingFlightDepartureRemoval = departure.addHours(4);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL'); // 2h flight
    Flight f2 = TestFlightFactory.create(
      'SK0002',
      connectingFlightDeparture,
      'HEL',
      'CPH'
    );

    List<Flight> flights = new List<Flight>{ f1, f2 };

    FlightIrregularity delay = TestIrregularityFactory.createDefaultDelay(f1);
    delay.durationMinutes = 75;
    List<FlightIrregularity> fis = new List<FlightIrregularity>{ delay };
    f1.irregularities = fis;
    f1.arrivalDelayedMinutes = 75;
    f1.actualArrivalTime = f1.scheduledArrivalTime.addMinutes(75);

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightDelayCompensation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);
    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      null
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      departure.addDays(-60),
      connectingFlightDepartureRemoval,
      TestSegmentFactory.History.DEFAULTCANCELLATION
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    return new BookingClaim(b, c);
  }

  private static BookingClaim getMoreComplicatedMissedConnectionBookingClaim() {
    // First flight is delayed leading to the passenger missing their next flight, ultimately leading to a 4 hour delay
    Datetime firstConnectingFlightDeparture = departure.addHours(3);
    Datetime secondConnectingFlightDeparture = departure.addHours(6);
    Datetime secondConnectingFlightDepartureRemoval = departure.addHours(7);
    Datetime secondConnectingFlightReplacementDeparture = departure.addHours(
      10
    );
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    Flight f2 = TestFlightFactory.create(
      'SK0002',
      firstConnectingFlightDeparture,
      'HEL',
      'CPH'
    ); // 2h flight
    Flight f3 = TestFlightFactory.create(
      'SK0003',
      secondConnectingFlightDeparture,
      'CPH',
      'LAX'
    );
    Flight f4 = TestFlightFactory.create(
      'SK0004',
      secondConnectingFlightReplacementDeparture,
      'CPH',
      'LAX'
    );
    List<Flight> flights = new List<Flight>{ f1, f2, f3, f4 };

    FlightIrregularity delay = TestIrregularityFactory.createDefaultDelay(f2);
    delay.durationMinutes = 75;
    List<FlightIrregularity> fis = new List<FlightIrregularity>{ delay };
    f2.irregularities = fis;
    f2.arrivalDelayedMinutes = 75;
    f2.actualArrivalTime = f2.scheduledArrivalTime.addMinutes(75);

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightDelayCompensation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);
    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      null
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      departure.addDays(-60),
      null
    );
    TestSegmentFactory.SegmentsInfo sInfo3 = new TestSegmentFactory.SegmentsInfo(
      f3,
      departure.addDays(-60),
      secondConnectingFlightDepartureRemoval,
      TestSegmentFactory.History.DEFAULTCANCELLATION
    );
    TestSegmentFactory.SegmentsInfo sInfo4 = new TestSegmentFactory.SegmentsInfo(
      f4,
      secondConnectingFlightDepartureRemoval,
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2,
      sInfo3,
      sInfo4
    };

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    return new BookingClaim(b, c);
  }

  private static BookingClaim getDefaultCancellationBookingClaim() {
    Datetime newDeparture = departure.addHours(3);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    f1.actualArrivalTime = null;
    f1.actualDepartureTime = null;
    Flight f2 = TestFlightFactory.create('SK0002', newDeparture, 'ARN', 'HEL');
    List<Flight> flights = new List<Flight>{ f1, f2 };

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellationCompensation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);
    c.preferredCompensationMethod = Claim.CompensationType.Monetary;
    c.preferredCurrency = Money.CurrencyCode.EUR;
    c.bankCountry = 'Sweden';
    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      cancellationTime.addMinutes(20)
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      cancellationTime.addMinutes(20),
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    return new BookingClaim(b, c);
  }

  private static BookingClaim get2HoursDelayedCancellationBookingClaim() {
    Datetime newDeparture = departure.addHours(2).addMinutes(1);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    f1.actualArrivalTime = null;
    f1.actualDepartureTime = null;
    Flight f2 = TestFlightFactory.create('SK0002', newDeparture, 'ARN', 'HEL');
    List<Flight> flights = new List<Flight>{ f1, f2 };

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    Datetime cancellationTime = departure.addDays(-10);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellationCompensation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);
    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      cancellationTime.addMinutes(20)
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      cancellationTime.addMinutes(20),
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    return new BookingClaim(b, c);
  }

  /**
    Based on:
    THVPPA  2022-02-15 19:44:00 LPA   OSL   1 A   0 HK         2022-07-01 2022-07-01
    THVPPA  2022-02-15 19:46:00 LPA   OSL   1 C   2 HK HK      2022-07-01 2022-07-01
    THVPPA  2022-03-10 20:51:00 LPA   OSL   1 C  10 UN HK      2022-07-01 2022-07-01
    THVPPA  2022-03-10 21:00:00 LPA   OSL   1 X  18 UN UN      2022-07-01 2022-07-01

    THVPPA  2022-03-10 20:51:00 LPA   OSL   2 A  10 TK         2022-06-29 2022-06-29
    THVPPA  2022-03-10 21:00:00 LPA   OSL   2 C  18 HK TK      2022-06-29 2022-06-29
    THVPPA  2022-03-11 08:54:00 LPA   OSL   2 X  23 XX HK      2022-06-29 2022-06-29

    THVPPA  2022-03-11 08:54:00 LPA   OSL   3 A  23 HK    CREW 2022-07-02 2022-07-02
    THVPPA  2022-03-11 08:54:00 LPA   OSL   3 C  24 HK HK CREW 2022-07-02 2022-07-02
    THVPPA  2022-07-01 17:25:00 LPA   OSL   3 C  46 UN HK CREW 2022-07-02 2022-07-02
    THVPPA  2022-07-01 17:59:00 LPA   OSL   3 X  51 UN UN CREW 2022-07-02 2022-07-02

    THVPPA  2022-07-01 17:59:00 LPA   BRU   4 A  51 HK    NaN 2022-07-03 2022-07-03
    THVPPA  2022-07-02 11:24:00 LPA   BRU   4 C  55 HK HK NaN 2022-07-03 2022-07-03
    THVPPA  2022-07-02 11:24:00 LPA   BRU   4 C  56 HK HK NaN 2022-07-03 2022-07-03

    THVPPA  2022-07-01 17:59:00 BRU   OSL   5 A  51 HK         2022-07-03 2022-07-03
    THVPPA  2022-07-02 11:24:00 BRU   OSL   5 C  55 HK HK      2022-07-03 2022-07-03
    THVPPA  2022-07-02 11:24:00 BRU   OSL   5 C  56 HK HK      2022-07-03 2022-07-03
   */
  private static BookingClaim getCancellationFullBookingHistory() {
    Datetime newDeparture1 = departure.addHours(4);
    Datetime newDeparture2 = departure.addDays(-2);
    Datetime newDeparture3 = departure.addDays(1);
    Datetime newDeparture4 = departure.addDays(1).addHours(5);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    Flight f2 = TestFlightFactory.create('SK0002', newDeparture1, 'ARN', 'HEL');
    Flight f3 = TestFlightFactory.create('SK0003', newDeparture2, 'ARN', 'HEL');
    Flight f4 = TestFlightFactory.create('SK0004', newDeparture3, 'ARN', 'CPH');
    Flight f5 = TestFlightFactory.create('SK0005', newDeparture4, 'CPH', 'HEL');
    List<Flight> flights = new List<Flight>{ f1, f2, f3, f4, f5 };

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f3)
    };

    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f3.irregularities = fis;

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellationCompensation;
    c.departureDate = newDeparture2.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0003'; // SK001 null reference
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);

    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    Datetime timeBooked = departure.addDays(-60);
    Datetime unconfirmedWithoutCancellation = departure.addDays(-45);
    Datetime cancelledWithoutCancellation = unconfirmedWithoutCancellation.addHours(
      2
    ); // 2 h default
    Datetime removed = cancelledWithoutCancellation.addDays(1);

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      timeBooked,
      unconfirmedWithoutCancellation,
      TestSegmentFactory.History.DOUBLEUNCONFIRMED
    );

    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      cancelledWithoutCancellation,
      removed,
      TestSegmentFactory.History.REMOVEDNOTCANCELLED
    );

    TestSegmentFactory.SegmentsInfo sInfo3 = new TestSegmentFactory.SegmentsInfo(
      f3,
      removed,
      cancellationTime,
      TestSegmentFactory.History.DEFAULTCANCELLATION
    );

    TestSegmentFactory.SegmentsInfo sInfo4 = new TestSegmentFactory.SegmentsInfo(
      f4,
      cancellationTime,
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    TestSegmentFactory.SegmentsInfo sInfo5 = new TestSegmentFactory.SegmentsInfo(
      f5,
      cancellationTime,
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2,
      sInfo3,
      sInfo4,
      sInfo5
    };

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    return new BookingClaim(b, c);
  }

  private static void verifyDelayResult(
    EU261Claim.Decision result,
    EU261Claim claimToEvaluate,
    Claim.EU261HandlingStatus expectedStatus,
    Money expectedCompensation,
    Money expectedReimbursement,
    String reasoning
  ) {
    System.assertEquals(
      expectedStatus,
      result.verdict,
      'Handling status should be "' + String.valueOf(expectedStatus) + '"'
    );

    if (expectedStatus == Claim.EU261HandlingStatus.EligibleForCompensation) {
      System.assertEquals(
        new Money(250, Money.CurrencyCode.EUR),
        result.compensationPerCustomerInEUR.values()[0],
        'Compensation should be ' + expectedCompensation.toString() + ' euros.'
      );
      System.assertEquals(
        new Money(0, Money.CurrencyCode.SEK),
        result.reimbursementAmountInSEK,
        'Reimbursement should be ' + expectedReimbursement.toString() + ' SEK.'
      );
    } else {
      // Check the reasoning
      System.assertEquals(
        reasoning,
        result.reasoning,
        'Reasoning should be "' + reasoning + '"'
      );
    }

    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      claimToEvaluate.protocol.getReport();
      System.assert(false, 'Could not make automation report.');
    }
  }

  @TestVisible
  private static EU261Claim getClaimWhereCustomerCancelledTheFlight() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0]
      .flight.irregularities[0]
      .cancellationTime = bc.b.segments[0]
      .flight.irregularities[0]
      .cancellationTime.addDays(1);
    List<SegmentEvent> newEvents = new List<SegmentEvent>();
    for (SegmentEvent se : bc.b.segments[0].getEvents()) {
      se.officeCode = 'STOSK08RV';
      if (se.newStatus == SegmentEvent.StatusCode.C_UN) {
        se.operationType = SegmentEvent.OperationType.C_X;
        se.newStatus = SegmentEvent.StatusCode.C_XX;
      }
      newEvents.add(se);
    }
    bc.b.segments[0].events = newEvents;

    return new EU261Claim(bc.c, new List<Booking>{ bc.b }, false, config);
  }

  @TestVisible
  private static EU261Claim getClaimWhereFlightWasCancelled14DaysOrMoreBeforeDeparture() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0]
      .flight.irregularities[0]
      .cancellationTime = departure.addDays(-14);

    return new EU261Claim(bc.c, new List<Booking>{ bc.b }, false, config);
  }

  @TestVisible
  private static EU261Claim getClaimWhereCustomerClaimedTooLate() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.c.createdDate = DateTime.newInstance(2030, 1, 1);

    return new EU261Claim(bc.c, new List<Booking>{ bc.b }, false, config);
  }

  @TestVisible
  private static EU261Claim getClaimWithCancellationsOutsideSASControl() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0].flight.irregularities[0].code = 'WEAT';
    bc.b.segments[0]
      .flight.irregularities[0]
      .eligibleForEU261 = FlightIrregularity.EU261Eligibility.No;

    return new EU261Claim(bc.c, new List<Booking>{ bc.b }, false, config);
  }

  @TestVisible
  private static EU261Claim getLongDistanceHalvedCompensationClaim() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Flight f1 = bc.b.segments[0].flight;
    Flight f2 = bc.b.segments[1].flight;
    f1.arrivalAirportObject = TestAirportFixture.codeToAirport.get('LAX');
    f1.arrivalAirport = 'LAX';
    f1.tedsIdentifier = f1.tedsIdentifier.substringBefore('HEL') + 'LAX';
    f2.arrivalAirportObject = TestAirportFixture.codeToAirport.get('LAX');
    f2.arrivalAirport = 'LAX';
    f2.tedsIdentifier = f2.tedsIdentifier.substringBefore('HEL') + 'LAX';

    return new EU261Claim(bc.c, new List<Booking>{ bc.b }, false, config);
  }

  @TestVisible
  private static EU261Claim getClaimWithTwoFlightsAndOneCancellationButOnTime() {
    Datetime newDeparture = departure.addHours(4);
    Datetime nextFlightDeparture = departure.addHours(7);

    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    Flight f2 = TestFlightFactory.create('SK0002', newDeparture, 'ARN', 'HEL');
    Flight f3 = TestFlightFactory.create(
      'SK0003',
      nextFlightDeparture,
      'HEL',
      'CPH'
    );

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      cancellationTime.addMinutes(20)
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      cancellationTime.addMinutes(20),
      null
    );
    TestSegmentFactory.SegmentsInfo sInfo3 = new TestSegmentFactory.SegmentsInfo(
      f3,
      departure.addDays(-60),
      null
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2,
      sInfo3
    };

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellationCompensation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);

    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    return new EU261Claim(c, new List<Booking>{ b }, false, config);
  }

  @TestVisible
  private static EU261Claim getClaimWithShortDelay() {
    BookingClaim bc = getDefaultDelayBookingClaim();
    Flight f = bc.b.segments[0].flight;
    f.irregularities[0].durationMinutes = 60;
    f.arrivalDelayedMinutes = 60;
    f.actualArrivalTime = bc.b.segments[0]
      .flight.scheduledArrivalTime.addMinutes(60);

    return new EU261Claim(bc.c, new List<Booking>{ bc.b }, false, config);
  }

  @TestVisible
  private static EU261Claim getLongDistanceClaim() {
    BookingClaim bc = getDefaultDelayBookingClaim();
    Flight f1 = bc.b.segments[0].flight;
    f1.arrivalAirportObject = TestAirportFixture.codeToAirport.get('LAX');
    f1.arrivalAirport = 'LAX';
    f1.tedsIdentifier = f1.tedsIdentifier.substringBefore('HEL') + 'LAX';

    return new EU261Claim(bc.c, new List<Booking>{ bc.b }, false, config);
  }

  @TestVisible
  private static EU261Claim getClaimWithDelayWhereSASNotInControl() {
    BookingClaim bc = getDefaultDelayBookingClaim();
    bc.b.segments[0].flight.irregularities[0].code = 'AF';
    bc.b.segments[0]
      .flight.irregularities[0]
      .eligibleForEU261 = FlightIrregularity.EU261Eligibility.No;

    return new EU261Claim(bc.c, new List<Booking>{ bc.b }, false, config);
  }

  @TestVisible
  private static EU261Claim getClaimWhereNoFlightIsDelayedOrCancelled() {
    BookingClaim bc = getDefaultDelayBookingClaim();
    Flight f = bc.b.segments[0].flight;
    f.actualArrivalTime = bc.b.segments[0].flight.scheduledArrivalTime;
    f.arrivalDelayedMinutes = 0;
    f.irregularities = new List<FlightIrregularity>();

    return new EU261Claim(bc.c, new List<Booking>{ bc.b }, false, config);
  }

  /**
   * Based on:
  res_id;res_crea_dte;off_cd;staff_pnr;res_upd_tms;office_updating;seg_tattoo;record_opr_type;res_upd_no;action_cd;prev_action_cd;flt_airl_cd;flt_nb;stn_fr_cd;stn_to_cd;dep_dte;opr_bkg_cl;opr_svc_cl;arr_dte;seg_status;aircraft_registration;flt_status;std_tms;sta_tms;etd_tms;eta_tms;atd_tms;ata_tms;arrival_delay_mins;dep_delay_mins;change_reason;suppl_info;is_latest
  NYCZTB ;2022-04-29 00:00:00;CPHSK08RV;N;2022-04-29 10:26:00;CPHSK08RV;1;A ;0;HK;  ;SK ;2517;CPH  ;BRI  ;2022-07-15 00:00:00;W;M;2022-07-15 00:00:00;ACTIVE;LNRGL   ;X;2022-07-15 13:40:00;2022-07-15 16:25:00;null;null;null;null;null;null;INDU;PILOT STRIKE;0
  NYCZTB ;2022-04-29 00:00:00;CPHSK08RV;N;2022-04-29 10:26:00;CPHSK08RV;2;A ;0;HK;  ;SK ;2518;BRI  ;CPH  ;2022-07-25 00:00:00;W;M;2022-07-25 00:00:00;ACTIVE;SEROS   ;F;2022-07-25 17:15:00;2022-07-25 20:00:00;null;2022-07-25 19:49:00;2022-07-25 17:26:00;2022-07-25 19:58:00;−2;11;    ;MINIMIZE DELAYS;0
  NYCZTB ;2022-04-29 00:00:00;CPHSK08RV;N;2022-04-29 10:28:00;CPHSK08RV;1;C ;2;HK;HK;SK ;2517;CPH  ;BRI  ;2022-07-15 00:00:00;W;M;2022-07-15 00:00:00;ACTIVE;LNRGL   ;X;2022-07-15 13:40:00;2022-07-15 16:25:00;null;null;null;null;null;null;INDU;PILOT STRIKE;0
  NYCZTB ;2022-04-29 00:00:00;CPHSK08RV;N;2022-04-29 10:28:00;CPHSK08RV;2;C ;2;HK;HK;SK ;2518;BRI  ;CPH  ;2022-07-25 00:00:00;W;M;2022-07-25 00:00:00;ACTIVE;SEROS   ;F;2022-07-25 17:15:00;2022-07-25 20:00:00;null;2022-07-25 19:49:00;2022-07-25 17:26:00;2022-07-25 19:58:00;−2;11;    ;MINIMIZE DELAYS;1
  NYCZTB ;2022-04-29 00:00:00;CPHSK08RV;N;2022-07-15 04:57:00;STOSK059A;1;C ;5;UN;HK;SK ;2517;CPH  ;BRI  ;2022-07-15 00:00:00;W;M;2022-07-15 00:00:00;CANCELLED;LNRGL   ;X;2022-07-15 13:40:00;2022-07-15 16:25:00;null;null;null;null;null;null;INDU;PILOT STRIKE;1
  */
  private static BookingClaim getCancellationFullBookingHistoryNoReplacement() {
    Datetime returnTime = departure.addDays(7);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'CPH', 'HEL');
    Flight f2 = TestFlightFactory.create('SK0002', returnTime, 'HEL', 'CPH');
    List<Flight> flights = new List<Flight>{ f1, f2 };

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellationCompensation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);

    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    Datetime timeBooked = departure.addDays(-60);
    Datetime unconfirmed = cancellationTime;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      timeBooked,
      unconfirmed,
      TestSegmentFactory.History.DEFAULTCANCELLATION
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      timeBooked,
      null,
      TestSegmentFactory.History.DEFAULTCONFIRMED
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    return new BookingClaim(b, c);
  }

  private static List<ClaimExpense> getDefaultExpenses() {
    ClaimExpense ce = new ClaimExpense();
    ce.amount = 20;
    ce.amountInSEK = 20;
    ce.currencyOfAmount = Money.CurrencyCode.SEK;
    return new List<ClaimExpense>{ ce };
  }

  @IsTest
  static void onlyClaimsWhichDoNotRequirePOACanBeEvaluated() {
    Datetime newDeparture = departure.addHours(4);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    Flight f2 = TestFlightFactory.create('SK0002', newDeparture, 'ARN', 'HEL');
    List<Flight> flights = new List<Flight>{ f1, f2 };
    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };
    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;
    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      cancellationTime.addMinutes(20)
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      cancellationTime.addMinutes(20),
      null
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    ClaimCustomer cc1 = new ClaimCustomer();
    cc1.firstname = 'Test';
    cc1.lastName = 'Testsson';
    ClaimCustomer cc2 = new ClaimCustomer();
    cc2.firstname = 'Test2';
    cc2.lastName = 'Testsson2';
    ClaimCustomer cc3 = new ClaimCustomer();
    cc3.firstname = 'Test3';
    cc3.lastName = 'Testsson3';
    ClaimCustomer cc4 = new ClaimCustomer();
    cc4.firstname = 'Test4';
    cc4.lastName = 'Testsson4';
    ClaimCustomer cc5 = new ClaimCustomer();
    cc5.firstname = 'Test5';
    cc5.lastName = 'Testsson5';
    ClaimCustomer cc6 = new ClaimCustomer();
    cc6.firstname = 'Test6';
    cc6.lastName = 'Testsdaughter';

    List<Claim> claimsWithoutCustomers = new List<Claim>();

    for (Integer i = 0; i < 4; i++) {
      Claim c = TestClaimFactory.create();
      c.recordType = Claim.RecordType.CustomerClaim;
      c.category = Claim.Category.FlightDisruptions;
      c.type = Claim.Type.FlightCancellationCompensation;
      c.departureDate = departure.date();
      c.flightNumber = 'SK0001';
      c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);
      c.customers = new List<ClaimCustomer>{ cc1 };
      claimsWithoutCustomers.add(c);
    }

    // groupBookingReference
    // Cloning these would be nice but there does not seem to be an easy solution
    Claim groupClaim = claimsWithoutCustomers[0];
    groupClaim.customers.add(cc2);
    groupClaim.customers.add(cc3);
    groupClaim.customers.add(cc4);
    groupClaim.customers.add(cc5);
    groupClaim.customers.add(cc6);
    Booking groupBooking = TestBookingFactory.createValidForClaim(groupClaim);
    groupBooking.type = Booking.Type.OneWay;

    groupBooking.segments = TestSegmentFactory.createFromBookingFlights(
      groupBooking,
      segmentInfos
    );

    // differentLastNamesReference
    Claim differentLastNameClaim = claimsWithoutCustomers[1];
    differentLastNameClaim.customers.add(cc6);
    Booking differentLastNameBooking = TestBookingFactory.createValidForClaim(
      differentLastNameClaim
    );
    differentLastNameBooking.type = Booking.Type.OneWay;
    differentLastNameBooking.segments = TestSegmentFactory.createFromBookingFlights(
      differentLastNameBooking,
      segmentInfos
    );

    // missingTravelersBookingReference, todo, Customer name != passenger name
    Claim missingTravelersClaim = claimsWithoutCustomers[2];
    missingTravelersClaim.customers.add(cc2);
    Booking missingTravelersBooking = TestBookingFactory.createValidForClaim(
      missingTravelersClaim
    );
    missingTravelersBooking.passengers[1].firstName = 'Missing';
    missingTravelersBooking.type = Booking.Type.OneWay;
    missingTravelersBooking.segments = TestSegmentFactory.createFromBookingFlights(
      missingTravelersBooking,
      segmentInfos
    );

    // claimFirmBookingReference
    Claim claimFirmClaim = claimsWithoutCustomers[3];
    claimFirmClaim.contactType = Claim.ContactType.ClaimFirm;
    Booking claimFirmBooking = TestBookingFactory.createValidForClaim(
      claimFirmClaim
    );
    claimFirmBooking.type = Booking.Type.OneWay;
    claimFirmBooking.segments = TestSegmentFactory.createFromBookingFlights(
      claimFirmBooking,
      segmentInfos
    );

    EU261Claim groupClaimToEvaluate = new EU261Claim(
      groupClaim,
      new List<Booking>{ groupBooking },
      false,
      config
    );
    EU261Claim differentLastNameClaimToEvaluate = new EU261Claim(
      differentLastNameClaim,
      new List<Booking>{ differentLastNameBooking },
      false,
      config
    );
    EU261Claim missingTravelersClaimToEvaluate = new EU261Claim(
      missingTravelersClaim,
      new List<Booking>{ missingTravelersBooking },
      false,
      config
    );
    EU261Claim claimFirmClaimToEvaluate = new EU261Claim(
      claimFirmClaim,
      new List<Booking>{ claimFirmBooking },
      false,
      config
    );

    EU261Claim.Decision groupResult = groupClaimToEvaluate.evaluate();
    EU261Claim.Decision differentLastNameResult = differentLastNameClaimToEvaluate.evaluate();
    EU261Claim.Decision missingTravelersResult = missingTravelersClaimToEvaluate.evaluate();
    EU261Claim.Decision claimFirmResult = claimFirmClaimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      groupResult.verdict,
      'It should not be possible to automatically evaluate a claim with more than four travelers.'
    );
    System.assertEquals(
      1,
      groupResult.caveats.size(),
      'There should be one caveat'
    );
    System.assertEquals(
      EU261Claim.SemiAutomationReason.RequiresPowerOfAttorney,
      groupResult.caveats[0],
      'Caveat should be power of attorney.'
    );

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      differentLastNameResult.verdict,
      'It should not be possible to automatically evaluate a claim with different last names.'
    );
    System.assertEquals(
      1,
      differentLastNameResult.caveats.size(),
      'There should be one caveat'
    );
    System.assertEquals(
      EU261Claim.SemiAutomationReason.RequiresPowerOfAttorney,
      differentLastNameResult.caveats[0],
      'Caveat should be power of attorney.'
    );

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      missingTravelersResult.verdict,
      'It should not be possible to automatically evaluate a claim when claimed travelers are not included in the booking.'
    );
    System.assertEquals(
      1,
      missingTravelersResult.caveats.size(),
      'There should be one caveat'
    );
    System.assertEquals(
      EU261Claim.SemiAutomationReason.RequiresPowerOfAttorney,
      missingTravelersResult.caveats[0],
      'Caveat should be power of attorney.'
    );

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      claimFirmResult.verdict,
      'It should not be possible to evaluate a claim submitted by a claim firm.'
    );
    System.assertEquals(
      1,
      claimFirmResult.caveats.size(),
      'There should be one caveat'
    );
    System.assertEquals(
      EU261Claim.SemiAutomationReason.RequiresPowerOfAttorney,
      claimFirmResult.caveats[0],
      'Caveat should be power of attorney.'
    );

    try {
      System.debug(groupClaimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report 1.');
    }
    try {
      System.debug(differentLastNameClaimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report 2.');
    }
    try {
      System.debug(missingTravelersClaimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report 3.');
    }
    try {
      System.debug(claimFirmClaimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report 4.');
    }
  }

  @IsTest
  static void onlyClaimsWithOneBookingCanBeEvaluated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b, bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Claim with more than one booking cannot be evaluated.'
    );
    System.assertEquals(
      'can handle only one booking per claim',
      result.reasoning,
      'Rejection reason should be "can handle only one booking per claim"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimsWhereFlightWasCancelled14DaysOrMoreBeforeDepartureShouldBeDenied() {
    EU261Claim claimToEvaluate = getClaimWhereFlightWasCancelled14DaysOrMoreBeforeDeparture();

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      result.verdict,
      'Claim where claimflight was cancelled 14+ days in advance should be ineligible for compensation.'
    );
    System.assertEquals(
      'Flight was cancelled 14 or more days in advance',
      result.reasoning,
      'Rejection reason should be "Flight was cancelled 14 or more days in advance"'
    );

    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void onlyClaimsWithoutExpensesCanBeEvaluated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();

    bc.c.submittedClaimExpenses = new Money(20, Money.CurrencyCode.SEK);
    bc.c.expenses = getDefaultExpenses();
    bc.c.type = Claim.Type.FlightCancellationExpenses;

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.ReimbursementOnly,
      result.verdict,
      'It should not be possible to automatically evaluate claims with expenses.'
    );
    System.assertEquals(1, result.caveats.size(), 'There should be one caveat');
    System.assertEquals(
      EU261Claim.SemiAutomationReason.HasHighClaimExpenses,
      result.caveats[0],
      'Caveat should be high expenses.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimsWhereCancellationOutsideSASControlWithExpensesShouldOnlyAllowExpenses() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0].flight.irregularities[0].code = 'WEAT';
    bc.b.segments[0]
      .flight.irregularities[0]
      .eligibleForEU261 = FlightIrregularity.EU261Eligibility.No;

    bc.c.submittedClaimExpenses = new Money(20, Money.CurrencyCode.SEK);
    bc.c.expenses = getDefaultExpenses();
    bc.c.type = Claim.Type.FlightCancellationExpenses;

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.ReimbursementOnly,
      result.verdict,
      'Customer should be eligible for reimbursement but not compensation.'
    );
    System.assertEquals(1, result.caveats.size(), 'There should be one caveat');
    System.assertEquals(
      EU261Claim.SemiAutomationReason.HasHighClaimExpenses,
      result.caveats[0],
      'Caveat should be high expenses.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimsWithCancellationDelayBetween2And3HoursShouldAllowExpensesButNotCompensation() {
    BookingClaim bc = get2HoursDelayedCancellationBookingClaim();

    bc.c.submittedClaimExpenses = new Money(20, Money.CurrencyCode.SEK);
    bc.c.expenses = getDefaultExpenses();
    bc.c.type = Claim.Type.FlightCancellationExpenses;

    BookingClaim bc2 = get2HoursDelayedCancellationBookingClaim();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim claimToEvaluate2 = new EU261Claim(
      bc2.c,
      new List<Booking>{ bc2.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();
    EU261Claim.Decision result2 = claimToEvaluate2.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.ReimbursementOnly,
      result.verdict,
      'Customer should be eligible for reimbursement.'
    );
    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      result2.verdict,
      'Customer should be not be eligible for compensation.'
    );
    System.assertEquals(
      null,
      result.compensationPerCustomerInEUR,
      'There should be no compensation.'
    );
    System.assertEquals(
      null,
      result2.compensationPerCustomerInEUR,
      'There should be no compensation.'
    );
    System.assertEquals(
      new Money(20, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 20 SEK.'
    );
    System.assertEquals(1, result.caveats.size(), 'There should be one caveat');
    System.assertEquals(
      0,
      result2.caveats.size(),
      'There should not be any caveats'
    );
    System.assertEquals(
      EU261Claim.SemiAutomationReason.HasHighClaimExpenses,
      result.caveats[0],
      'Caveat should be high expenses.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
      System.debug(claimToEvaluate2.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void onlyClaimsWithClaimedFlightInBookingCanBeEvaluated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.c.flightNumber = 'SK0009';

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'It should not be possible to evaluate claims with flight missing from booking.'
    );
    System.assertEquals(
      'cannot find claimed flight from booking',
      result.reasoning,
      'Rejection reason should be "cannot find claimed flight from booking"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimsWithRotationIrregularitiesFromHubCanBeEvaluated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0].flight.irregularities[0].code = 'CREW';

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'It should be possible to evaluate claims with CREW delays.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void onlyClaimsWithClaimFlightOperatedBySASCanBeEvaluated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Flight nonSASFlight = TestFlightFactory.create(
      'LH0001',
      departure.addHours(4),
      'ARN',
      'HEL'
    );
    bc.b.segments[0]
      .flight.tedsIdentifier = Flight.constructTEDSFlightNumberDate(
      'LH0001',
      bc.c.departureDate
    );
    bc.b.segments[0].flight.operatingCarrier = 'LH';
    bc.c.flightNumber = 'LH0001';

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'It should not be possible to evaluate claims where the claim flight not operated by SAS.'
    );
    System.assertEquals(
      'claim flight is not operated by SAS',
      result.reasoning,
      'Rejection reason should be "claim flight is not operated by SAS"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void onlyClaimsWithoutDuplicatesCanBeEvaluated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      true,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.PossiblyEligibleForCompensation,
      result.verdict,
      'It should not be possible to automatically evaluate claims with possible duplicates.'
    );
    System.assertEquals(1, result.caveats.size(), 'There should be one caveat');
    System.assertEquals(
      EU261Claim.SemiAutomationReason.HasPotentialDuplicates,
      result.caveats[0],
      'Caveat should be duplicates.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void minimalClaimShouldBeEvaluatedCorrectly() {
    BookingClaim bc = getDefaultCancellationBookingClaim();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'Handling status should be "Eligible for compensation"'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'Compensation should be 250 euros.'
    );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 0 euros.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void minimalClaimWithExpensesShouldBeEvaluatedCorrectly() {
    BookingClaim bc = getDefaultCancellationBookingClaim(); // Remove?
    bc.c.submittedClaimExpenses = new Money(20, Money.CurrencyCode.SEK);
    bc.c.expenses = getDefaultExpenses();
    bc.c.type = Claim.Type.FlightCancellationExpenses;

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.ReimbursementOnly,
      result.verdict,
      'Handling status should be "ReimbursementOnly"'
    );
    System.assertEquals(
      null,
      result.compensationPerCustomerInEUR,
      'There should not be any compensation.'
    );
    System.assertEquals(
      new Money(20, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 20 SEK.'
    );
    System.assertEquals(1, result.caveats.size(), 'There should be one caveat');
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWhereCustomerClaimedTooLateShouldBeDenied() {
    EU261Claim claimToEvaluate = getClaimWhereCustomerClaimedTooLate();

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      result.verdict,
      'A claim where the customer filed too late should be denied'
    );
    System.assertEquals(
      'Claim was not filed on on time',
      result.reasoning,
      'Reasoning should be "Claim was not filed on on time"'
    );

    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void minimalClaimOutsideTheEUShouldBeEvaluatedCorrectly() {
    EU261Claim claimToEvaluate = getLongDistanceHalvedCompensationClaim();

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'Handling status should be "Eligible for compensation"'
    );
    System.assertEquals(
      new Money(300, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'Compensation should be 300 euros.'
    );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 0 euros.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void minimalCancellationClaimWithoutRebookingShouldReceiveFullCompensation() {
    Datetime newDeparture = departure.addHours(4);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      cancellationTime.addMinutes(20)
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1
    };

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellationCompensation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);

    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    EU261Claim claimToEvaluate = new EU261Claim(
      c,
      new List<Booking>{ b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'A booking without rebooking should be awarded full compensation'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'Compensation should be €250'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void minimalCancellationClaimsWithCancellationsOutsideSASControlShouldBeDenied() {
    EU261Claim claimToEvaluate = getClaimWithCancellationsOutsideSASControl();

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      result.verdict,
      'It should be possible to evaluate minimal claims with cancellations outside SAS control and they should not receive any compensation.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimsWithUnsupportedCancellationCodesShouldNotBeAutomated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0].flight.irregularities[0].code = 'AIRS';
    bc.b.segments[0]
      .flight.irregularities[0]
      .eligibleForEU261 = FlightIrregularity.EU261Eligibility.Tentative;

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'It should not be possible to evaluate claims with unsupported cancellation codes.'
    );
    System.assertEquals(
      'cannot determine wether SAS is responsible or not for the cancellation | Cannot determine whether SAS is within control or not.',
      result.reasoning,
      'Unhandled reason should be "cannot determine wether SAS is responsible or not for the cancellation"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimsWithTwoCancellationsShouldNotBeAutomated() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Flight f = bc.b.segments[0].flight;
    FlightIrregularity newIrreg = TestIrregularityFactory.createCancellation(f);
    newIrreg.code = 'TECH';
    f.irregularities.add(newIrreg);

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Should not be able to handle claim'
    );
    System.assertEquals(
      'there are more than one cancellation connected to the claim flight',
      result.reasoning,
      'Unhandled reason should be "there are more than one cancellation connected to the claim flight"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimsWithTwoFlightsAndOneCancellationNotOnTimeShouldBeApproved() {
    Datetime newDeparture = departure.addHours(4);
    Datetime nextFlightDeparture = departure.addHours(3);
    Datetime nextFlightDepartureReplacement = departure.addHours(6);

    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    Flight f2 = TestFlightFactory.create('SK0002', newDeparture, 'ARN', 'HEL');
    Flight f3 = TestFlightFactory.create(
      'SK0003',
      nextFlightDeparture,
      'HEL',
      'CPH'
    );
    Flight f4 = TestFlightFactory.create(
      'SK0004',
      nextFlightDepartureReplacement,
      'HEL',
      'CPH'
    );

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      cancellationTime.addMinutes(20),
      TestSegmentFactory.History.DEFAULTCANCELLATION
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      cancellationTime.addMinutes(20),
      null
    );
    TestSegmentFactory.SegmentsInfo sInfo3 = new TestSegmentFactory.SegmentsInfo(
      f3,
      departure.addDays(-60),
      cancellationTime.addMinutes(20),
      TestSegmentFactory.History.DEFAULTCANCELLATION
    );
    TestSegmentFactory.SegmentsInfo sInfo4 = new TestSegmentFactory.SegmentsInfo(
      f4,
      cancellationTime.addMinutes(20),
      null
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2,
      sInfo3,
      sInfo4
    };

    ClaimCustomer cc = new ClaimCustomer();
    cc.firstname = 'Test';
    cc.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellationCompensation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc };
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);

    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);
    b.segments[2].tripType = 'Cancelled';

    EU261Claim claimToEvaluate = new EU261Claim(
      c,
      new List<Booking>{ b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'If a cancelled flight leads to a missed connection and a delay of +3 hours the customer should be eligble for compensation (two flights).'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'The customer should be awarded 250 eur (two flights)'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimsWithTwoFlightsAndOneCancellationButOnTimeShouldBeDenied() {
    EU261Claim claimToEvaluate = getClaimWithTwoFlightsAndOneCancellationButOnTime();

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      result.verdict,
      'If a cancelled flight does not affect the final arrival time the customer should not be compensated (two flights).'
    );
    System.assertEquals(
      'The offered rebooking is not outside the timeframe allowed by EU261',
      result.reasoning,
      'If a cancelled flight does not affect the final arrival time the customer should not be compensated (two flights).'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimsWithAnyNumberOfPassengersCanBeEvaluated() {
    Datetime newDeparture = departure.addHours(4);
    Flight f1 = TestFlightFactory.create('SK0001', departure, 'ARN', 'HEL');
    Flight f2 = TestFlightFactory.create('SK0002', newDeparture, 'ARN', 'HEL');

    List<FlightIrregularity> fis = new List<FlightIrregularity>{
      TestIrregularityFactory.createCancellation(f1)
    };

    Datetime cancellationTime = departure.addDays(-1);
    fis[0].cancellationTime = cancellationTime;
    f1.irregularities = fis;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      f1,
      departure.addDays(-60),
      cancellationTime.addMinutes(20)
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      f2,
      cancellationTime.addMinutes(20),
      null
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    ClaimCustomer cc1 = new ClaimCustomer();
    cc1.firstname = 'Test';
    cc1.lastName = 'Testsson';
    ClaimCustomer cc2 = new ClaimCustomer();
    cc2.firstname = 'Test2';
    cc2.lastName = 'Testsson';

    Claim c = TestClaimFactory.create();
    c.recordType = Claim.RecordType.CustomerClaim;
    c.category = Claim.Category.FlightDisruptions;
    c.type = Claim.Type.FlightCancellationCompensation;
    c.departureDate = departure.date();
    c.customers = new List<ClaimCustomer>{ cc1, cc2 }; // Is this correctly implemented?
    c.flightNumber = 'SK0001';
    c.submittedClaimExpenses = new Money(0, Money.CurrencyCode.SEK);

    Booking b = TestBookingFactory.createValidForClaim(c);
    b.type = Booking.Type.OneWay;

    b.segments = TestSegmentFactory.createFromBookingFlights(b, segmentInfos);

    EU261Claim claimToEvaluate = new EU261Claim(
      c,
      new List<Booking>{ b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'It should be possible to evaluate a claim with two passengers.'
    );
    System.assertEquals(
      2,
      result.compensationPerCustomerInEUR.values().size(),
      'Settlement total should be larger for two passenger.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'Compensation should be 250€ for first customer'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[1],
      'Compensation should be 250€ for second customer'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void minimalCancellationClaimShouldBeAutomatedCorrectly() {
    // A rebooked flight which arrives 4h later than the original flight.
    BookingClaim bc = getDefaultCancellationBookingClaim();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'The minimal cancellation claim should be automated.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'We should pay out €250 for the minimal cancellation claim'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWhereTheCustomerCancelledTheFlightShouldBeDenied() {
    // A rebooked flight which arrives 4h later than the original flight.
    EU261Claim claimToEvaluate = getClaimWhereCustomerCancelledTheFlight();

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      result.verdict,
      'A claim where the customer cancelled the flight should not be automated'
    );
    System.assertEquals(
      'The customer cancelled the flight',
      result.reasoning,
      'Reasoning should be "The customer cancelled the flight"'
    );

    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWhereTheSASRemovedTheFlightShouldBeApproved() {
    // A rebooked flight which arrives 4h later than the original flight.
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0]
      .flight.irregularities[0]
      .cancellationTime = bc.b.segments[0]
      .flight.irregularities[0]
      .cancellationTime.addDays(1);
    List<SegmentEvent> newEvents = new List<SegmentEvent>();
    for (SegmentEvent se : bc.b.segments[0].getEvents()) {
      se.officeCode = 'STOSK0001';
      if (se.newStatus == SegmentEvent.StatusCode.C_UN) {
        se.operationType = SegmentEvent.OperationType.C_X;
        se.newStatus = SegmentEvent.StatusCode.C_XX;
      }
      newEvents.add(se);
    }
    bc.b.segments[0].events = newEvents;

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'Claim where a segment has been removed without being cancelled should be evaluated.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'We should pay out €250 for the minimal cancellation claim'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWithRemovedButNotCancelledSegmentsAfterCancellationShouldBeAutomated() {
    // Create a default booking but edit the segment history
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Flight cancelledFlight = bc.b.segments[0].flight;
    Flight replacementFlight = bc.b.segments[1].flight;
    Datetime cancellationTime = cancelledFlight.irregularities[0]
      .cancellationTime;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      cancelledFlight,
      departure.addDays(-60),
      cancellationTime.addMinutes(20),
      TestSegmentFactory.History.REMOVEDNOTCANCELLED
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      replacementFlight,
      cancellationTime.addMinutes(20),
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    bc.b.segments = TestSegmentFactory.createFromBookingFlights(
      bc.b,
      segmentInfos
    );

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'Claim where a segment has been removed without being cancelled should be evaluated.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'We should pay out €250 for the minimal cancellation claim'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWithRemovedButNotCancelledSegmentsBeforeCancellationShouldBeAutomatedWithCaveats() {
    // Create a default booking but edit the segment history
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Flight cancelledFlight = bc.b.segments[0].flight;
    Flight replacementFlight = bc.b.segments[1].flight;
    Datetime cancellationTime = cancelledFlight.irregularities[0]
      .cancellationTime;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      cancelledFlight,
      departure.addDays(-60),
      cancellationTime.addMinutes(-20),
      TestSegmentFactory.History.REMOVEDNOTCANCELLED
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      replacementFlight,
      cancellationTime.addMinutes(-20),
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    bc.b.segments = TestSegmentFactory.createFromBookingFlights(
      bc.b,
      segmentInfos
    );

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Claim where a segment has been removed without being cancelled should not be evaluated.'
    );
    System.assertEquals(
      'it is uncertain if SAS or the customer cancelled the flight',
      result.reasoning,
      'Reasoning should be "it is uncertain if SAS or the customer cancelled the flight"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWithUnsupportedSegmentEventsShouldNotBeAutomated() {
    // Create a default booking but edit the segment history
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Flight cancelledFlight = bc.b.segments[0].flight;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      cancelledFlight,
      departure.addDays(-60),
      null,
      TestSegmentFactory.History.UNABLETOCONFIRM
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1
    };

    bc.b.segments = TestSegmentFactory.createFromBookingFlights(
      bc.b,
      segmentInfos
    );

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'A claim with segments which have unsupported segment events should not be handled.'
    );
    System.assertEquals(
      'booking has unsupported event(s)',
      result.reasoning,
      'Unhandled reason should be "booking has unsupported event(s)"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWithGroupSegmentEventShouldNotBeAutomated() {
    // Create a default booking but edit the segment history
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Flight cancelledFlight = bc.b.segments[0].flight;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      cancelledFlight,
      departure.addDays(-60),
      null,
      TestSegmentFactory.History.GROUPBOOKING
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1
    };

    bc.b.segments = TestSegmentFactory.createFromBookingFlights(
      bc.b,
      segmentInfos
    );

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'A claim with segments which have group segment events should not be handled.'
    );
    System.assertEquals(
      'booking has unsupported event(s)',
      result.reasoning,
      'Unhandled reason should be "booking has unsupported event(s)"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWithTwoUnconfirmedStatusesShouldBeAutomated() {
    // Create a default booking but edit the segment history
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Flight cancelledFlight = bc.b.segments[0].flight;
    Flight replacementFlight = bc.b.segments[1].flight;
    Datetime cancellationTime = cancelledFlight.irregularities[0]
      .cancellationTime;

    TestSegmentFactory.SegmentsInfo sInfo1 = new TestSegmentFactory.SegmentsInfo(
      cancelledFlight,
      departure.addDays(-60),
      cancellationTime.addMinutes(20),
      TestSegmentFactory.History.DOUBLEUNCONFIRMED
    );
    TestSegmentFactory.SegmentsInfo sInfo2 = new TestSegmentFactory.SegmentsInfo(
      replacementFlight,
      cancellationTime.addMinutes(140),
      null,
      TestSegmentFactory.History.DEFAULTREPLACEMENT
    );

    List<TestSegmentFactory.SegmentsInfo> segmentInfos = new List<TestSegmentFactory.SegmentsInfo>{
      sInfo1,
      sInfo2
    };

    bc.b.segments = TestSegmentFactory.createFromBookingFlights(
      bc.b,
      segmentInfos
    );

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'The minimal cancellation claim should be automated.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'We should pay out €250 for the minimal cancellation claim'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }
  @IsTest
  static void claimWithFullHistoryShouldBeAutomated() {
    BookingClaim bc = getCancellationFullBookingHistory();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'The minimal cancellation claim should be automated.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'We should pay out €250 for the minimal cancellation claim'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWithComplicatedHistoryNoReplacementShouldBeAutomated() {
    BookingClaim bc = getCancellationFullBookingHistoryNoReplacement();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'The minimal cancellation claim should be automated.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'We should pay out €250 for the minimal cancellation claim'
    );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'We should not pay out reimbursement for the minimal cancellation claim'
    );

    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWithoutSegmentEventsShouldNotCrashEvaluation() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.b.segments[0].setEvents(null);

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Claims without segment events should not be possible to handle'
    );
    System.assertEquals(
      'cannot get segment statuses',
      result.reasoning,
      'Reasoning should be "cannot get segment statuses"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  // DELAY
  @IsTest
  static void minimalDelayClaimShouldBeEvaluatedCorrectly() {
    BookingClaim bc = getDefaultDelayBookingClaim();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'Handling status should be "Eligible for compensation"'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'Compensation should be 250 euros.'
    );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 0 euros.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWithShortDelayShouldBeDenied() {
    EU261Claim claimToEvaluate = getClaimWithShortDelay();

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      result.verdict,
      'Handling status should be "Ineligible for compensation"'
    );
    System.assertEquals(
      'Delayed less than 180 minutes',
      result.reasoning,
      'Reasoning should be "Delayed less than 180 minutes"'
    );
    System.assertEquals(
      null,
      result.compensationPerCustomerInEUR,
      'Compensation should be 0 euros.'
    );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 0 euros.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void longDistanceDelayBetween3And4HoursShouldAward300EUR() {
    // DISABLED pending email template creation
    EU261Claim claimToEvaluate = getLongDistanceClaim();

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Handling status should be "Eligible for compensation" (CURRENTLY DISABLED -> Unabletohandle)'
    );
    // System.assertEquals(
    //   new Money(300, Money.CurrencyCode.EUR),
    //   result.compensationPerCustomerInEUR.values()[0],
    //   'Compensation should be 300 euros (halved).'
    // );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 0 euros.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void delayWhereSASNotInControlShouldBeDenied() {
    EU261Claim claimToEvaluate = getClaimWithDelayWhereSASNotInControl();

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      result.verdict,
      'Claims with delays where SAS is not in control should be denied.'
    );
    System.assertEquals(
      'SAS is not responsible for 3 hours or more of the delay',
      result.reasoning,
      'Rejection reason should be "SAS is not responsible for 3 hours or more of the delay"'
    );

    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void delayWhereNotCertainIfSASInControlShouldNotBeHandled() {
    BookingClaim bc = getDefaultDelayBookingClaim();
    bc.b.segments[0].flight.irregularities[0].code = 'DG';
    bc.b.segments[0].flight.irregularities[0].eligibleForEU261 = null;

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Delay where it is not certain if SAS is within control should not be handled.'
    );
    System.assertEquals(
      'Cannot determine whether SAS is within control or not.',
      result.reasoning,
      'Rejection reason should be "Cannot determine whether SAS is within control or not."'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void rotationDelaysShouldNotBeHandled() {
    BookingClaim bc = getDefaultDelayBookingClaim();
    bc.b.segments[0].flight.irregularities[0].code = 'RA';
    bc.b.segments[0]
      .flight.irregularities[0]
      .eligibleForEU261 = FlightIrregularity.EU261Eligibility.Tentative;

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Delay claim with rotation should not be handled.'
    );
    System.assertEquals(
      'Cannot determine whether SAS is within control or not.',
      result.reasoning,
      'Rejection reason should be "Cannot determine whether SAS is within control or not."'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void tentativeDelaysShouldNotBeHandled() {
    BookingClaim bc = getDefaultDelayBookingClaim();
    bc.b.segments[0].flight.irregularities[0].code = 'AS';
    bc.b.segments[0]
      .flight.irregularities[0]
      .eligibleForEU261 = FlightIrregularity.EU261Eligibility.Tentative;

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Claim with tentative delay claim should not be handled.'
    );
    System.assertEquals(
      'Cannot determine whether SAS is within control or not.',
      result.reasoning,
      'Rejection reason should be "Cannot determine whether SAS is within control or not."'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void delayBetween2And3HoursShouldOnlyBeAwardedReimbursement() {
    BookingClaim bc = getDefaultDelayBookingClaim();
    Flight f = bc.b.segments[0].flight;
    f.irregularities[0].durationMinutes = 121;
    f.arrivalDelayedMinutes = 121;
    f.actualArrivalTime = bc.b.segments[0]
      .flight.scheduledArrivalTime.addMinutes(121);

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    BookingClaim bcExpenses = bc.clone();
    bcExpenses.c.submittedClaimExpenses = new Money(20, Money.CurrencyCode.SEK);
    bcExpenses.c.expenses = getDefaultExpenses();
    bcExpenses.c.type = Claim.Type.FlightDelayExpenses;
    EU261Claim claimToEvaluateExpenses = new EU261Claim(
      bcExpenses.c,
      new List<Booking>{ bcExpenses.b },
      false,
      config
    );

    EU261Claim.Decision resultExpenses = claimToEvaluateExpenses.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      result.verdict,
      'Handling status should be "IneligibleForCompensation"'
    );
    System.assertEquals(
      Claim.EU261HandlingStatus.ReimbursementOnly,
      resultExpenses.verdict,
      'Handling status should be "ReimbursementOnly"'
    );
    System.assertEquals(
      null,
      result.compensationPerCustomerInEUR,
      'Compensation should be 0 euros.'
    );
    System.assertEquals(
      null,
      resultExpenses.compensationPerCustomerInEUR,
      'Compensation should be 0 euros.'
    );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 0 euros.'
    );
    System.assertEquals(
      new Money(20, Money.CurrencyCode.SEK),
      resultExpenses.reimbursementAmountInSEK,
      'Reimbursement should be 20 euros.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
      System.debug(claimToEvaluateExpenses.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWithMultipleDelaysShouldBeEvaluated() {
    BookingClaim bc = getDefaultDelayBookingClaim();
    Flight f = bc.b.segments[0].flight;
    f.irregularities[0].durationMinutes = 60;
    f.irregularities.add(TestIrregularityFactory.createDelay(f, 'CA', 120));
    f.arrivalDelayedMinutes = 180;
    f.actualArrivalTime = bc.b.segments[0]
      .flight.scheduledArrivalTime.addMinutes(180);

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'Handling status should be "Eligible for compensation"'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'Compensation should be 250 euros.'
    );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 0 euros.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWhereThereAreBothDelaysWithinAndOutsideSASControlShouldNotBeEvaluated() {
    BookingClaim bc = getDefaultDelayBookingClaim();
    Flight f = bc.b.segments[0].flight;
    f.irregularities[0].durationMinutes = 60;
    f.irregularities.add(TestIrregularityFactory.createDelay(f, 'AF', 120));
    f.arrivalDelayedMinutes = 180;
    f.actualArrivalTime = bc.b.segments[0]
      .flight.scheduledArrivalTime.addMinutes(180);

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Handling status should be "Unable to handle"'
    );
    System.assertEquals(
      'the delay is too complicated',
      result.reasoning,
      'Reasoning should be "the delay is too complicated"'
    );
    System.assertEquals(
      null,
      result.compensationPerCustomerInEUR,
      'Compensation should be 0 euros.'
    );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 0 euros.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWhereNoFlightIsDelayedOrCancelledShouldBeDenied() {
    EU261Claim claimToEvaluate = getClaimWhereNoFlightIsDelayedOrCancelled();

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Claim where flight is not delayed or cancelled should not be handled'
    );
    System.assertEquals(
      'flight not cancelled and not delayed',
      result.reasoning,
      'Rejection reason should be "flight not cancelled and not delayed"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWhereClaimFlightIsCancelledButCustomerClaimedDelayShouldBeHandled() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    bc.c.type = Claim.Type.FlightDelayCompensation;

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'Claim where flight is cancelled but the customer claimed for delay should be handled.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'Compensation should be 250 EUR'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWhereClaimFlightIsDelayedButCustomerClaimedCancellationShouldNotBeHandled() {
    BookingClaim bc = getDefaultDelayBookingClaim();
    bc.c.type = Claim.Type.FlightCancellationCompensation;

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Claim where flight is delayed but the cusomer claimed for cancellation should not be handled.'
    );
    System.assertEquals(
      'the claim flight is not cancelled',
      result.reasoning,
      'Rejection reason should be "the claim flight is not cancelled"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimsWithInvalidIrregularitiesShouldNotBeHandled() {
    BookingClaim bc1 = getDefaultCancellationBookingClaim();
    Flight f1 = bc1.b.segments[0].flight;
    FlightIrregularity newIrreg1 = TestIrregularityFactory.createCancellation(
      f1
    );
    newIrreg1.type = 'CANCELLED';
    newIrreg1.code = 'N/A';
    newIrreg1.description = null;
    newIrreg1.durationMinutes = 0;
    newIrreg1.cancellationTime = null;
    newIrreg1.eligibleForEU261 = FlightIrregularity.EU261Eligibility.Tentative;
    f1.irregularities = new List<FlightIrregularity>{ newIrreg1 };

    BookingClaim bc2 = getDefaultCancellationBookingClaim();
    Flight f2 = bc2.b.segments[0].flight;
    FlightIrregularity newIrreg2 = TestIrregularityFactory.createCancellation(
      f2
    );
    newIrreg2.type = 'CANCELLED';
    newIrreg2.code = null;
    newIrreg2.description = null;
    newIrreg2.durationMinutes = 0;
    newIrreg2.cancellationTime = departure.addDays(-7);
    newIrreg2.eligibleForEU261 = FlightIrregularity.EU261Eligibility.Tentative;
    f2.irregularities = new List<FlightIrregularity>{ newIrreg2 };

    List<EU261Claim> claimsToEvaluate = new List<EU261Claim>{
      new EU261Claim(bc1.c, new List<Booking>{ bc1.b }, false, config),
      new EU261Claim(bc2.c, new List<Booking>{ bc2.b }, false, config)
    };

    List<EU261Claim.Decision> results = new List<EU261Claim.Decision>();

    for (EU261Claim claimToEvaluate : claimsToEvaluate) {
      results.add(claimToEvaluate.evaluate());
    }

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      results[0].verdict,
      'Claim with invalid irregularities should not be handled.'
    );
    System.assertEquals(
      'the claim flight has an invalid irregularity',
      results[0].reasoning,
      'Unable reason should be "the claim flight has an invalid irregularity"'
    );
    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      results[1].verdict,
      'Claim with invalid irregularities should not be handled.'
    );
    System.assertEquals(
      'cannot determine wether SAS is responsible or not for the cancellation | Cannot determine whether SAS is within control or not.',
      results[1].reasoning,
      'Unable reason should be "cannot determine wether SAS is responsible or not for the cancellation | Cannot determine whether SAS is within control or not."'
    );
  }

  /**
   * ROBUST DELAY TESTING
   * Legend:
   * ____________________
   * | + = YES          |
   * | - = NO           |
   * | / = TENTATIVE    |
   * | ? = Unaccounted  |
   * | _ = *Empty*      |
   * |__________________|
   *
   * 1. fullYesDelay (minimalDelayClaim):
   * |++++++++++| => Yes
   * 2. fullNoDelay (delayWhereSASNotInControl):
   * |----------| => No
   * 3. shortYesDelay (claimWithShortDelay):
   * |++++++++__| => No
   * 4. shortMixedDelay:
   * |+++++/-?__| => No
   * 5. fullYesNoDelay (claimWhereThereAreBothDelaysWithinAndOutsideSASControlShouldNotBeEvaluated):
   * |++++------| => Manual handling
   * 6. fullYesSmallNoDelay:
   * |++++++++++|+- => Manual handling
   * 7. smallYesFullNoDelay:
   * |+---------|-- => Manual handling
   * 8. fullYesSmallUnaccountedDelay:
   * |+++++++++?| => No
   * 9. fullYesMediumUnaccountedDelay:
   * |+++++++???| => No
   * 10. fullYesLargeUnaccountedDelay:
   * |+?????????| => Manual handling
   * 11. superMixedDelay:
   * |++++--////|?? => Manual handling
   * 12. tenativeDelay (tentativeDelaysShouldNotBeHandled, delayWhereNotCertainIfSASInControlShouldNotBeHandled):
   * |//////////| => Manual handling (TODO: remove semi duplicate test)
   *
   * Standard delay codes:
   * CA => Yes
   * AF => No
   * PS => Tentative
   */

  @IsTest
  static void shortMixedDelay() {
    // |+++++/-?__|
    BookingClaim bc = getDefaultDelayBookingClaim();
    Flight f = bc.b.segments[0].flight;
    f.irregularities[0].durationMinutes = 60;
    f.irregularities.add(TestIrregularityFactory.createDelay(f, 'AF', 30));
    f.irregularities.add(TestIrregularityFactory.createDelay(f, 'PS', 30));
    Integer unaccountedForDelayMinutes = 5;
    Integer totalDelay = unaccountedForDelayMinutes + 60 + 30 + 30;

    f.arrivalDelayedMinutes = totalDelay;
    f.actualArrivalTime = bc.b.segments[0]
      .flight.scheduledArrivalTime.addMinutes(totalDelay);

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    verifyDelayResult(
      result,
      claimToEvaluate,
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      new Money(0, Money.CurrencyCode.EUR),
      new Money(0, Money.CurrencyCode.SEK),
      'Delayed less than 180 minutes'
    );
  }

  @IsTest
  static void fullYesSmallNoDelay() {
    // |++++++++++|+-
    BookingClaim bc = getDefaultDelayBookingClaim();
    Flight f = bc.b.segments[0].flight;
    f.irregularities[0].durationMinutes = 200;
    f.irregularities.add(TestIrregularityFactory.createDelay(f, 'AF', 30));
    Integer totalDelay = 200 + 30;

    f.arrivalDelayedMinutes = totalDelay;
    f.actualArrivalTime = bc.b.segments[0]
      .flight.scheduledArrivalTime.addMinutes(totalDelay);

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    verifyDelayResult(
      result,
      claimToEvaluate,
      Claim.EU261HandlingStatus.UnableToHandle,
      null,
      null,
      'the delay is too complicated'
    );
  }

  @IsTest
  static void smallYesFullNoDelay() {
    // |+---------|--
    BookingClaim bc = getDefaultDelayBookingClaim();
    Flight f = bc.b.segments[0].flight;
    f.irregularities[0].durationMinutes = 20;
    f.irregularities.add(TestIrregularityFactory.createDelay(f, 'AF', 200));
    Integer totalDelay = 20 + 200;

    f.arrivalDelayedMinutes = totalDelay;
    f.actualArrivalTime = bc.b.segments[0]
      .flight.scheduledArrivalTime.addMinutes(totalDelay);

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    verifyDelayResult(
      result,
      claimToEvaluate,
      Claim.EU261HandlingStatus.UnableToHandle,
      null,
      null,
      'the delay is too complicated'
    );
  }

  @IsTest
  static void fullYesSmallUnaccountedDelay() {
    // |+++++++++?|
    BookingClaim bc = getDefaultDelayBookingClaim();
    Flight f = bc.b.segments[0].flight;
    f.irregularities[0].durationMinutes = 175;
    Integer unaccountedForDelayMinutes = 5;
    Integer totalDelay = unaccountedForDelayMinutes + 175;

    f.arrivalDelayedMinutes = totalDelay;
    f.actualArrivalTime = bc.b.segments[0]
      .flight.scheduledArrivalTime.addMinutes(totalDelay);

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    verifyDelayResult(
      result,
      claimToEvaluate,
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      null,
      null,
      'SAS is not responsible for 3 hours or more of the delay'
    );
  }

  @IsTest
  static void fullYesMediumUnaccountedDelay() {
    // |+++++++???|
    BookingClaim bc = getDefaultDelayBookingClaim();
    Flight f = bc.b.segments[0].flight;
    f.irregularities[0].durationMinutes = 160;
    Integer unaccountedForDelayMinutes = 30;
    Integer totalDelay = unaccountedForDelayMinutes + 160;

    f.arrivalDelayedMinutes = totalDelay;
    f.actualArrivalTime = bc.b.segments[0]
      .flight.scheduledArrivalTime.addMinutes(totalDelay);

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    verifyDelayResult(
      result,
      claimToEvaluate,
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      null,
      null,
      'SAS is not responsible for 3 hours or more of the delay'
    );
  }

  @IsTest
  static void fullYesLargeUnaccountedDelay() {
    // |+?????????|
    BookingClaim bc = getDefaultDelayBookingClaim();
    Flight f = bc.b.segments[0].flight;
    f.irregularities[0].durationMinutes = 30;
    Integer unaccountedForDelayMinutes = 200;
    Integer totalDelay = unaccountedForDelayMinutes + 30;

    f.arrivalDelayedMinutes = totalDelay;
    f.actualArrivalTime = bc.b.segments[0]
      .flight.scheduledArrivalTime.addMinutes(totalDelay);

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    verifyDelayResult(
      result,
      claimToEvaluate,
      Claim.EU261HandlingStatus.UnableToHandle,
      null,
      null,
      'There is a large delay which is not accounted for by the irregularities'
    );
  }

  @IsTest
  static void superMixedDelay() {
    // |++++--////|??
    BookingClaim bc = getDefaultDelayBookingClaim();
    Flight f = bc.b.segments[0].flight;
    f.irregularities[0].durationMinutes = 60;
    f.irregularities.add(TestIrregularityFactory.createDelay(f, 'AF', 60));
    f.irregularities.add(TestIrregularityFactory.createDelay(f, 'PS', 60));
    Integer unaccountedForDelayMinutes = 60;
    Integer totalDelay = unaccountedForDelayMinutes + 60 + 60 + 60;

    f.arrivalDelayedMinutes = totalDelay;
    f.actualArrivalTime = bc.b.segments[0]
      .flight.scheduledArrivalTime.addMinutes(totalDelay);

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    verifyDelayResult(
      result,
      claimToEvaluate,
      Claim.EU261HandlingStatus.UnableToHandle,
      null,
      null,
      'Cannot determine whether SAS is within control or not.'
    );
  }

  @IsTest
  static void canGetRootCauseSimpleDelay() {
    BookingClaim bc = getDefaultDelayBookingClaim();

    Trip.RootCause rootCause = bc.b.getRootCauseAndEffect(
      bc.b.segments[0].flight
    );

    System.assertEquals(
      'The last flight was the cause of the delay.',
      rootCause.description
    );
    System.assertEquals(
      bc.b.segments[0].flight.tedsIdentifier,
      rootCause.flight.tedsIdentifier,
      'Root cause flight should be the first flight'
    );
  }

  @IsTest
  static void canGetRootCauseShortDelay() {
    BookingClaim bc = getDefaultDelayBookingClaim();

    Flight f = bc.b.segments[0].flight;
    f.irregularities[0].durationMinutes = 60;
    f.irregularities.add(TestIrregularityFactory.createDelay(f, 'AF', 30));
    f.irregularities.add(TestIrregularityFactory.createDelay(f, 'PS', 30));
    Integer unaccountedForDelayMinutes = 5;
    Integer totalDelay = unaccountedForDelayMinutes + 60 + 30 + 30;

    f.arrivalDelayedMinutes = totalDelay;
    f.actualArrivalTime = bc.b.segments[0]
      .flight.scheduledArrivalTime.addMinutes(totalDelay);

    Trip.RootCause rootCause = bc.b.getRootCauseAndEffect(f);

    System.assertEquals('Delay is less than 3 hours', rootCause.description);
    System.assertEquals(null, rootCause.flight, 'Root cause should be null');
  }

  @IsTest
  static void canGetRootCauseMixedDelay() {
    BookingClaim bc = getDefaultDelayBookingClaim();
    Flight f = bc.b.segments[0].flight;
    f.irregularities[0].durationMinutes = 60;
    f.irregularities.add(TestIrregularityFactory.createDelay(f, 'AF', 60));
    f.irregularities.add(TestIrregularityFactory.createDelay(f, 'PS', 60));
    Integer unaccountedForDelayMinutes = 60;
    Integer totalDelay = unaccountedForDelayMinutes + 60 + 60 + 60;

    f.arrivalDelayedMinutes = totalDelay;
    f.actualArrivalTime = bc.b.segments[0]
      .flight.scheduledArrivalTime.addMinutes(totalDelay);

    Trip.RootCause rootCause = bc.b.getRootCauseAndEffect(f);

    System.assertEquals(
      'The last flight was the cause of the delay.',
      rootCause.description
    );
    System.assertEquals(
      f.tedsIdentifier,
      rootCause.flight.tedsIdentifier,
      'Root cause flight should be the first flight'
    );
  }

  @IsTest
  static void canGetRootCauseCancellation() {
    BookingClaim bc = getDefaultCancellationBookingClaim();

    Trip.RootCause rootCause = bc.b.getRootCauseAndEffect(
      bc.b.segments[0].flight
    );

    System.assertEquals(
      'The first cancellation in this booking is the root cause',
      rootCause.description
    );
    System.assertEquals(
      bc.b.segments[0].flight.tedsIdentifier,
      rootCause.flight.tedsIdentifier,
      'Root cause flight should be the first flight'
    );
  }

  @IsTest
  static void canGetRootCauseComplicatedCancellation() {
    BookingClaim bc = getCancellationFullBookingHistory();

    Trip.RootCause rootCause = bc.b.getRootCauseAndEffect(
      bc.b.segments[0].flight
    );

    System.assertEquals(
      'The first cancellation in this booking is the root cause',
      rootCause.description
    );
    System.assertEquals(
      bc.b.segments[2].flight.tedsIdentifier,
      rootCause.flight.tedsIdentifier,
      'Root cause flight should be the first flight'
    );
  }

  @IsTest
  static void canGetRootCauseNoReplacementCancellation() {
    BookingClaim bc = getCancellationFullBookingHistoryNoReplacement();

    Trip.RootCause rootCause = bc.b.getRootCauseAndEffect(
      bc.b.segments[0].flight
    );

    System.assertEquals(
      'The first cancellation in this booking is the root cause(no replacement trip)',
      rootCause.description
    );
    System.assertEquals(
      bc.b.segments[0].flight.tedsIdentifier,
      rootCause.flight.tedsIdentifier,
      'Root cause flight should be the first flight'
    );
  }

  // INCORRECTLY SORTED CLAIMS
  @IsTest
  static void incorrectlySortedMinimalCancellationClaimShouldBeAutomatedCorrectly() {
    // A rebooked flight which arrives 4h later than the original flight.
    BookingClaim bc1 = getDefaultCancellationBookingClaim();
    BookingClaim bc2 = getDefaultCancellationBookingClaim();
    bc1.c.type = Claim.Type.FlightDelayCompensation;
    bc2.c.type = Claim.Type.MissedConnectionCompensation;

    List<EU261Claim> claimsToEvaluate = new List<EU261Claim>{
      new EU261Claim(bc1.c, new List<Booking>{ bc1.b }, false, config),
      new EU261Claim(bc2.c, new List<Booking>{ bc2.b }, false, config)
    };

    List<EU261Claim.Decision> results = new List<EU261Claim.Decision>();

    for (EU261Claim claimToEvaluate : claimsToEvaluate) {
      results.add(claimToEvaluate.evaluate());
    }

    for (EU261Claim.Decision result : results) {
      System.assertEquals(
        '',
        result.reasoning,
        'Incorrectly sorted minimal cancellation claims should be automated.'
      );
      System.assertEquals(
        Claim.EU261HandlingStatus.EligibleForCompensation,
        result.verdict,
        'Incorrectly sorted minimal cancellation claims should be automated.'
      );
      System.assertEquals(
        new Money(250, Money.CurrencyCode.EUR),
        result.compensationPerCustomerInEUR.values()[0],
        'We should pay out €250 for incorrectly sorted minimal cancellation claim'
      );
    }
  }

  @IsTest
  static void cancellationClaimWithIncorrectClaimFlightShouldNotBeAutomatedCorrectly() {
    BookingClaim bc = getCancellationFullBookingHistory();

    bc.c.departureDate = bc.c.departureDate.addDays(2);
    bc.c.flightNumber = 'SK0001';

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Cancellation claim with incorrect flight should not be automated.'
    );
    System.assertEquals(
      'the claim flight is not cancelled',
      result.reasoning,
      'The reasoning should be "the claim flight is not cancelled"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void incorrectlySortedMinimalDelayClaimShouldNotBeAutomated() {
    BookingClaim bc1 = getDefaultDelayBookingClaim();
    BookingClaim bc2 = getDefaultDelayBookingClaim();

    bc1.c.type = Claim.Type.FlightCancellationCompensation;
    bc2.c.type = Claim.Type.MissedConnectionCompensation;

    List<EU261Claim> claimsToEvaluate = new List<EU261Claim>{
      new EU261Claim(bc1.c, new List<Booking>{ bc1.b }, false, config),
      new EU261Claim(bc2.c, new List<Booking>{ bc2.b }, false, config)
    };

    List<EU261Claim.Decision> results = new List<EU261Claim.Decision>();

    for (EU261Claim claimToEvaluate : claimsToEvaluate) {
      results.add(claimToEvaluate.evaluate());
    }

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      results[0].verdict,
      'Minimal delay claims sorted as a cancellation should not be automated.'
    );
    System.assertEquals(
      'the claim flight is not cancelled',
      results[0].reasoning,
      'The reasoning should be "the claim flight is not cancelled"'
    );

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      results[1].verdict,
      'Minimal delay claims sorted as a missed connection should  be automated.'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      results[1].compensationPerCustomerInEUR.values()[0],
      'Compensation should be 250 euros.'
    );
  }

  @IsTest
  static void minimalMissedConnectionClaimShouldBeEvaluatedCorrectly() {
    BookingClaim bc = getDefaultMissedConnectionBookingClaim();
    bc.c.type = Claim.Type.MissedConnectionCompensation;

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'Handling status should be "Eligible for compensation"'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'Compensation should be 250 euros.'
    );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 0 euros.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void longRangeMissedConnectionClaimShouldBeEvaluatedCorrectly() {
    BookingClaim bc = getMoreComplicatedMissedConnectionBookingClaim();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'Handling status should be "Eligible for compensation"'
    );
    System.assertEquals(
      new Money(600, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'Compensation should be 600 euros.'
    );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 0 euros.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void missedConnectionWithoutReplacementClaimShouldBeEvaluatedCorrectly() {
    BookingClaim bc = getDefaultMissedConnectionBookingClaimWithoutReplacement();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Handling status should be "Unable to handle"'
    );
    System.assertEquals(
      'could not sort and set root cause | The origin or destination airport changed',
      result.reasoning,
      'Unable reason should be "could not sort and set root cause | The origin or destination airport changed"'
    );
  }

  @IsTest
  static void bookingWithHiddenCancellationShouldNotBeAutomated() {
    // A rebooked flight which arrives 4h later than the original flight.
    BookingClaim bc = getHiddenCancellationBookingClaim();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Hidden cancellation claim should not be automated.'
    );
    System.assertEquals(
      'this claim likely has a hidden cancellation',
      result.reasoning,
      'Unable reason should be "this claim likely has a hidden cancellation"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void bookingWithEarlyUNShouldNotBeAutomated() {
    // A rebooked flight which arrives 4h later than the original flight.
    BookingClaim bc = getMissedConnectionWhereDelayResultedInEarlyUNBookingClaim();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.UnableToHandle,
      result.verdict,
      'Hidden cancellation claim should not be automated.'
    );
    System.assertEquals(
      'could not sort and set root cause | The affected trip has a flight which could have been removed because of a future delay',
      result.reasoning,
      'Unable reason should be "The affected trip has a flight which could have been removed because of a future delay"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void flightProactivityClaimShouldBeEvaluatedCorrectly() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Date today = departure.date();
    Proactivity__c flightProcativity = new Proactivity__c(
      Note__c = 'Test 1',
      Type__c = 'Normal',
      Airport__c = 'HEL',
      Match_Flights_Arriving_To_Airport__c = true,
      Match_Flights_Departing_Airport__c = false,
      From_Date__c = today,
      To_Date__c = today,
      Automate_Matching_Claims__c = true,
      EU261_Eligibility__c = 'Yes',
      Eligibility_Explanation__c = 'Test'
    );

    // Change the code of the irregularity connected to the flight
    bc.b.segments[0].flight.irregularities[0].code = 'FUEL';

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    claimToEvaluate.flightIdToProactivities.put(
      bc.b.segments[0].flight.id,
      new Set<Proactivity__c>{ flightProcativity }
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'Handling status should be "Eligible for compensation"'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'Compensation should be 250 euros.'
    );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 0 euros.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void denialFlightProactivityClaimShouldBeEvaluatedCorrectly() {
    BookingClaim bc = getDefaultCancellationBookingClaim();
    Date today = departure.date();
    Proactivity__c flightProcativity = new Proactivity__c(
      Note__c = 'Test 1',
      Type__c = 'Normal',
      Airport__c = 'HEL',
      Match_Flights_Arriving_To_Airport__c = true,
      Match_Flights_Departing_Airport__c = false,
      From_Date__c = today,
      To_Date__c = today,
      Automate_Matching_Claims__c = true,
      EU261_Eligibility__c = 'No',
      Eligibility_Explanation__c = 'Test'
    );

    // Change the code of the irregularity connected to the flight
    bc.b.segments[0].flight.irregularities[0].code = 'FUEL';

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    claimToEvaluate.flightIdToProactivities.put(
      bc.b.segments[0].flight.id,
      new Set<Proactivity__c>{ flightProcativity }
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      result.verdict,
      'Handling status should be "Ineligible for compensation"'
    );
    System.assertEquals(
      'Cancellation code not within SAS control (proactivity)',
      result.reasoning,
      'Rejection reason should be "Cancellation code not within SAS control (proactivity)"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimProactivityClaimShouldBeEvaluatedCorrectly() {
    BookingClaim bc = getDefaultCancellationBookingClaim();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    Date today = departure.date();
    Proactivity__c claimProcativity = new Proactivity__c(
      Note__c = 'Test 1',
      Type__c = 'Normal',
      Email__c = 'test@example.com',
      Automate_Matching_Claims__c = true,
      EU261_Eligibility__c = 'Tentative',
      Eligibility_Explanation__c = 'Test'
    );

    claimToEvaluate.claimProactivities = new Set<Proactivity__c>{
      claimProcativity
    };

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.WillNotHandle,
      result.verdict,
      'Handling status should be "Will not handle"'
    );
    System.assertEquals(
      'claim has a "Tentative" proactivity',
      result.reasoning,
      'Reasoning should be "claim has a "Tentative" proactivity"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void claimWithShortDelayAndApprovalProactivityShouldBeDenied() {
    EU261Claim claimToEvaluate = getClaimWithShortDelay();

    Date today = departure.date();
    Proactivity__c flightProcativity = new Proactivity__c(
      Note__c = 'Test 1',
      Type__c = 'Normal',
      Airport__c = 'HEL',
      Match_Flights_Arriving_To_Airport__c = true,
      Match_Flights_Departing_Airport__c = false,
      From_Date__c = today,
      To_Date__c = today,
      Automate_Matching_Claims__c = true,
      EU261_Eligibility__c = 'Yes',
      Eligibility_Explanation__c = 'Test'
    );

    claimToEvaluate.flightIdToProactivities.put(
      claimToEvaluate.claimedBooking.segments[0].flight.id,
      new Set<Proactivity__c>{ flightProcativity }
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      result.verdict,
      'Handling status should be "Ineligible for compensation"'
    );
    System.assertEquals(
      'Delayed less than 180 minutes',
      result.reasoning,
      'Reasoning should be "Delayed less than 180 minutes"'
    );
    System.assertEquals(
      null,
      result.compensationPerCustomerInEUR,
      'Compensation should be 0 euros.'
    );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 0 euros.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void proactivitySuperMixedDelay() {
    // |++++--////|??
    BookingClaim bc = getDefaultDelayBookingClaim();
    Flight f = bc.b.segments[0].flight;
    f.irregularities[0].durationMinutes = 60;
    f.irregularities.add(TestIrregularityFactory.createDelay(f, 'AF', 60));
    f.irregularities.add(TestIrregularityFactory.createDelay(f, 'PS', 60));
    Integer unaccountedForDelayMinutes = 60;
    Integer totalDelay = unaccountedForDelayMinutes + 60 + 60 + 60;

    f.arrivalDelayedMinutes = totalDelay;
    f.actualArrivalTime = bc.b.segments[0]
      .flight.scheduledArrivalTime.addMinutes(totalDelay);

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    Date today = departure.date();
    Proactivity__c flightProcativity = new Proactivity__c(
      Note__c = 'Test 1',
      Type__c = 'Normal',
      Airport__c = 'HEL',
      Match_Flights_Arriving_To_Airport__c = true,
      Match_Flights_Departing_Airport__c = false,
      From_Date__c = today,
      To_Date__c = today,
      Automate_Matching_Claims__c = true,
      EU261_Eligibility__c = 'Yes',
      Eligibility_Explanation__c = 'Test'
    );

    claimToEvaluate.flightIdToProactivities.put(
      bc.b.segments[0].flight.id,
      new Set<Proactivity__c>{ flightProcativity }
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.EligibleForCompensation,
      result.verdict,
      'Handling status should be "Eligible for compensation"'
    );
    System.assertEquals(
      new Money(250, Money.CurrencyCode.EUR),
      result.compensationPerCustomerInEUR.values()[0],
      'Compensation should be 250 euros.'
    );
    System.assertEquals(
      new Money(0, Money.CurrencyCode.SEK),
      result.reimbursementAmountInSEK,
      'Reimbursement should be 0 euros.'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }

  @IsTest
  static void proactivityDenialDelayClaimShouldBeEvaluatedCorrectly() {
    BookingClaim bc = getDefaultDelayBookingClaim();

    EU261Claim claimToEvaluate = new EU261Claim(
      bc.c,
      new List<Booking>{ bc.b },
      false,
      config
    );

    Date today = departure.date();
    Proactivity__c flightProcativity = new Proactivity__c(
      Note__c = 'Test 1',
      Type__c = 'Normal',
      Airport__c = 'HEL',
      Match_Flights_Arriving_To_Airport__c = true,
      Match_Flights_Departing_Airport__c = false,
      From_Date__c = today,
      To_Date__c = today,
      Automate_Matching_Claims__c = true,
      EU261_Eligibility__c = 'No',
      Eligibility_Explanation__c = 'Test'
    );

    claimToEvaluate.flightIdToProactivities.put(
      bc.b.segments[0].flight.id,
      new Set<Proactivity__c>{ flightProcativity }
    );

    EU261Claim.Decision result = claimToEvaluate.evaluate();

    System.assertEquals(
      Claim.EU261HandlingStatus.IneligibleForCompensation,
      result.verdict,
      'Handling status should be "Eligible for compensation"'
    );
    System.assertEquals(
      'SAS is not responsible for 3 hours or more of the delay (proactivity)',
      result.reasoning,
      'Reasoning should be "SAS is not responsible for 3 hours or more of the delay (proactivity)"'
    );
    try {
      System.debug(claimToEvaluate.protocol.getReport());
    } catch (Exception e) {
      System.assert(false, 'Could not make automation report.');
    }
  }
}
