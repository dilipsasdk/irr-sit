@IsTest
public with sharing class FlightIrregularity_Test {
  @IsTest
  public static void WEATwithEUYesShouldBeEligible() {
    FlightIrregularities__c EUYesWEAT = new FlightIrregularities__c(
      Code__c = 'WEAT',
      Reason__c = '',
      Type__c = 'Cancellation (departure)',
      Eligible_For_EU261__c = 'Yes'
    );

    Boolean isWithinSASControl = new FlightIrregularity(EUYesWEAT)
      .isWithinSASControl();

    System.assert(
      isWithinSASControl,
      'An irregularity which is not normally within SAS control with Eligible_For_EU261__c = "YES" should be in SAS control.'
    );
  }

  @IsTest
  public static void WEATwithEUTentativeShouldNotBeEligible() {
    FlightIrregularities__c EUTentativeWEAT = new FlightIrregularities__c(
      Code__c = 'WEAT',
      Reason__c = '',
      Type__c = 'Cancellation (departure)',
      Eligible_For_EU261__c = 'Tentative'
    );

    Boolean isWithinSASControl = new FlightIrregularity(EUTentativeWEAT)
      .isWithinSASControl();

    System.assert(
      !isWithinSASControl,
      'An irregularity which is not normally within SAS control with Eligible_For_EU261__c = "Tentativ" should not be in SAS control.'
    );
  }

  @IsTest
  public static void TECHwithEUNoShouldNotBeEligible() {
    FlightIrregularities__c EUNoTECH = new FlightIrregularities__c(
      Code__c = 'TECH',
      Reason__c = '',
      Type__c = 'Cancellation (departure)',
      Eligible_For_EU261__c = 'No'
    );

    Boolean isWithinSASControl = new FlightIrregularity(EUNoTECH)
      .isWithinSASControl();

    System.assert(
      !isWithinSASControl,
      'An irregularity which is normally within SAS control with Eligible_For_EU261__c = "NO" should not be in SAS control.'
    );
  }

  @isTest
  public static void evaluateCREWResponsibility() {
    Flight__c f = new Flight__c(
      Arrival_Airport__c = 'HEL',
      Departure_Airport__c = 'CPH',
      Operating_Carrier__c = 'SK',
      TEDS_Identifier__c = 'SK0003-20220818',
      Scheduled_Departure_Time__c = DateTime.newInstance(2022, 8, 18, 0, 1, 0),
      Scheduled_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 2, 1, 0),
      Actual_Arrival_Time__c = DateTime.newInstance(2022, 8, 18, 4, 11, 0)
    );

    insert f;

    FlightIrregularities__c CREWfromHub = new FlightIrregularities__c(
      Flight__c = f.Id,
      Code__c = 'CREW',
      Reason__c = '',
      Type__c = 'Cancellation (departure)',
      Eligible_For_EU261__c = 'Tentative'
    );

    insert CREWfromHub;

    FlightIrregularities irr = new FlightIrregularities(
      new List<FlightIrregularities__c>{ CREWfromHub }
    );
    irr.setEU261EligibilityForCREWIrregularities();

    Boolean isWithinSASControl = new FlightIrregularity(CREWfromHub)
      .isWithinSASControl();

    System.assert(
      isWithinSASControl,
      'A CREW irregularity from a hub should be within sas control'
    );
  }

  @IsTest
  public static void cancellationTypesShouldBeAnalyzedCorrectly() {
    Datetime standardTime = DateTime.newInstance(2022, 8, 18, 0, 1, 0);
    Datetime invalidTime = DateTime.newInstanceGmt(1900, 1, 1, 0, 0, 0);

    // Regular cancellation
    FlightIrregularities__c regularCancellation = new FlightIrregularities__c(
      Name__c = 'regularCancellation',
      Code__c = 'WEAT',
      Cancellation_Time__c = standardTime,
      Type__c = 'Cancellation (departure)',
      Duration_Minutes__c = null
    );
    FlightIrregularities__c regularCancellationNewType = regularCancellation.clone();
    regularCancellationNewType.Name__c = 'regularCancellationNewType';
    regularCancellationNewType.Type__c = 'CANCELLED';

    // Cancellation no code
    FlightIrregularities__c noCodeCancellation = regularCancellation.clone();
    noCodeCancellation.Name__c = 'noCodeCancellation';
    noCodeCancellation.Code__c = 'N/A';

    // Cancellation null code
    FlightIrregularities__c nullCodeCancellation = regularCancellation.clone();
    nullCodeCancellation.Name__c = 'nullCodeCancellation';
    nullCodeCancellation.Code__c = null;

    // Cancellation invalid time
    FlightIrregularities__c invalidTimeCancellation = regularCancellation.clone();
    invalidTimeCancellation.Name__c = 'invalidTimeCancellation';
    invalidTimeCancellation.Cancellation_Time__c = invalidTime;

    // Cancellation invalid time no code
    FlightIrregularities__c invalidTimeCancellationNoCode = invalidTimeCancellation.clone();
    invalidTimeCancellationNoCode.Code__c = 'N/A';

    // Cancellation arrival
    FlightIrregularities__c arrivalCancellation = new FlightIrregularities__c(
      Name__c = 'arrivalCancellation',
      Code__c = 'N/A',
      Type__c = 'Cancellation (arrival)',
      Cancellation_Time__c = null,
      Duration_Minutes__c = null
    );

    FlightIrregularities__c arrivalCancellationInvalidTime = arrivalCancellation.clone();
    arrivalCancellationInvalidTime.Name__c = 'arrivalCancellationInvalidTime';
    arrivalCancellationInvalidTime.Code__c = 'N/A';
    arrivalCancellationInvalidTime.Cancellation_Time__c = invalidTime;

    FlightIrregularities__c arrivalCancellationDifferentType = arrivalCancellation.clone();
    arrivalCancellationDifferentType.Name__c = 'arrivalCancellationDifferentType';
    arrivalCancellationDifferentType.Code__c = 'N/A';
    arrivalCancellationDifferentType.Type__c = 'CANCELLED';

    // Regular delay
    FlightIrregularities__c regularDelay = new FlightIrregularities__c(
      Name__c = 'regularDelay',
      Code__c = 'RA',
      Type__c = 'Delay (departure)',
      Duration_Minutes__c = 120,
      Cancellation_Time__c = null
    );
    FlightIrregularities__c arrivalDelay = regularDelay.clone();
    arrivalDelay.Name__c = 'arrivalDelay';
    arrivalDelay.Type__c = 'Delay (arrival)';
    FlightIrregularities__c arrivalDelayNewType = regularDelay.clone();
    arrivalDelayNewType.Name__c = 'arrivalDelayNewType';
    arrivalDelayNewType.Type__c = 'ARRIVAL DELAYED';
    FlightIrregularities__c arrivalAndDepartureDelayNewType = regularDelay.clone();
    arrivalAndDepartureDelayNewType.Name__c = 'arrivalAndDepartureDelayNewType';
    arrivalAndDepartureDelayNewType.Type__c = 'DEPARTUE AND ARRIVAL DELAYED';

    // Delay without code but with duration
    FlightIrregularities__c delayWithoutCode = regularDelay.clone();
    delayWithoutCode.Name__c = 'delayWithoutCode';
    delayWithoutCode.Code__c = 'N/A';
    FlightIrregularities__c delayWithNullCode = regularDelay.clone();
    delayWithNullCode.Name__c = 'delayWithNullCode';
    delayWithNullCode.Code__c = null;

    // Delay without duration
    FlightIrregularities__c delayWithoutDuration = regularDelay.clone();
    delayWithoutDuration.Name__c = 'delayWithoutDuration';
    delayWithoutDuration.Duration_Minutes__c = null;

    // Delay without code or duration
    FlightIrregularities__c delayWithoutCodeOrDuration = regularDelay.clone();
    delayWithoutCodeOrDuration.Name__c = 'delayWithoutCodeOrDuration';
    delayWithoutCodeOrDuration.Code__c = 'N/A';
    delayWithoutCodeOrDuration.Duration_Minutes__c = null;
    FlightIrregularities__c delayWithNullCodeOrDuration = delayWithoutCodeOrDuration.clone();
    delayWithNullCodeOrDuration.Name__c = 'delayWithNullCodeOrDuration';
    delayWithNullCodeOrDuration.Code__c = null;

    // Unknown code
    FlightIrregularities__c unknownCodeIrregularity = regularDelay.clone();
    unknownCodeIrregularity.Name__c = 'unknownCodeIrregularity';
    unknownCodeIrregularity.Code__c = 'QQ';

    Map<FlightIrregularity, FlightIrregularity.IrregularityType> irregularityToCorrectType = new Map<FlightIrregularity, FlightIrregularity.IrregularityType>{
      new FlightIrregularity(
        regularCancellation
      ) => FlightIrregularity.IrregularityType.CANCELLATION,
      new FlightIrregularity(
        regularCancellationNewType
      ) => FlightIrregularity.IrregularityType.CANCELLATION,
      new FlightIrregularity(
        noCodeCancellation
      ) => FlightIrregularity.IrregularityType.CANCELLATION,
      new FlightIrregularity(
        nullCodeCancellation
      ) => FlightIrregularity.IrregularityType.CANCELLATION,
      new FlightIrregularity(
        invalidTimeCancellation
      ) => FlightIrregularity.IrregularityType.CANCELLATION,
      new FlightIrregularity(invalidTimeCancellationNoCode) => null,
      new FlightIrregularity(
        arrivalCancellation
      ) => FlightIrregularity.IrregularityType.INVALID,
      new FlightIrregularity(
        arrivalCancellationInvalidTime
      ) => FlightIrregularity.IrregularityType.INVALID,
      new FlightIrregularity(arrivalCancellationDifferentType) => null,
      new FlightIrregularity(
        regularDelay
      ) => FlightIrregularity.IrregularityType.DELAY,
      new FlightIrregularity(
        arrivalDelay
      ) => FlightIrregularity.IrregularityType.DELAY,
      new FlightIrregularity(
        arrivalDelayNewType
      ) => FlightIrregularity.IrregularityType.DELAY,
      new FlightIrregularity(
        arrivalAndDepartureDelayNewType
      ) => FlightIrregularity.IrregularityType.DELAY,
      new FlightIrregularity(
        delayWithoutCode
      ) => FlightIrregularity.IrregularityType.DELAY,
      new FlightIrregularity(
        delayWithNullCode
      ) => FlightIrregularity.IrregularityType.DELAY,
      new FlightIrregularity(
        delayWithoutDuration
      ) => FlightIrregularity.IrregularityType.DELAY, // CHANGE?
      new FlightIrregularity(
        delayWithoutCodeOrDuration
      ) => FlightIrregularity.IrregularityType.INVALID,
      new FlightIrregularity(
        delayWithNullCodeOrDuration
      ) => FlightIrregularity.IrregularityType.INVALID,
      new FlightIrregularity(unknownCodeIrregularity) => null
    };

    List<FlightIrregularities__c> unknownIrregularities = new List<FlightIrregularities__c>{
      invalidTimeCancellationNoCode,
      arrivalCancellationDifferentType,
      unknownCodeIrregularity
    };

    Integer noUnknownIrregularitiesIdentified = 0;
    for (FlightIrregularity irregularity : irregularityToCorrectType.keySet()) {
      FlightIrregularity.IrregularityType correctType = irregularityToCorrectType.get(
        irregularity
      );
      FlightIrregularity.IrregularityType irregularityType;

      try {
        irregularityType = irregularity.getType();
      } catch (FlightIrregularity.UnknownIrregularityException e) {
        if (unknownIrregularities.contains(irregularity.underlyingSObject)) {
          noUnknownIrregularitiesIdentified += 1;
        } else {
          System.assert(
            false,
            'Known irregularity should not be unknown (' +
            irregularity.nameC +
            ')'
          );
        }
      }

      System.assertEquals(
        correctType,
        irregularityType,
        'Irregularity type should be ' +
        correctType +
        ' but was ' +
        irregularityType +
        ' (' +
        irregularity.nameC +
        ')'
      );
    }

    System.assertEquals(
      3,
      noUnknownIrregularitiesIdentified,
      'Commercial cancellations should have been identified'
    );
  }

  @IsTest
  public static void getKeywordTest() {
    List<FlightIrregularity.KeywordResponsibility> simpleMatchingKeywords = FlightIrregularity.getMatchingKeywords(
      'Birdstrike, taking off from ARN'
    );

    List<FlightIrregularity.KeywordResponsibility> singleNoMatchingKeywords = FlightIrregularity.getMatchingKeywords(
      'Bird caused go-around when taking off from LLA'
    );

    List<FlightIrregularity.KeywordResponsibility> doubleMatchingKeywords = FlightIrregularity.getMatchingKeywords(
      'Ground DAMA during STORM'
    );

    List<FlightIrregularity.KeywordResponsibility> noMatchingKeywords = FlightIrregularity.getMatchingKeywords(
      'BIRD flying around, Damage on ground, hailstorm'
    );

    System.assertEquals(
      1,
      simpleMatchingKeywords.size(),
      'Should have found one matching keyword'
    );

    System.assertEquals(
      0,
      singleNoMatchingKeywords.size(),
      'Should have found one matching keyword'
    );

    System.assertEquals(
      2,
      doubleMatchingKeywords.size(),
      'Should have found two matching keywords'
    );

    System.assertEquals(
      0,
      noMatchingKeywords.size(),
      'Should have found no matching keywords'
    );

    System.assertEquals(
      'a bird strike on the aircraft assigned to your flight',
      simpleMatchingKeywords[0].explanation,
      'Explanation should be a bird strike on the aircraft assigned to your flight'
    );

    System.assertEquals(
      'damage related to ground handling',
      doubleMatchingKeywords[0].explanation,
      'Explanation should be damage related to ground handling'
    );

    System.assertEquals(
      'adverse weather conditions',
      doubleMatchingKeywords[1].explanation,
      'Explanation should be adverse weather conditions'
    );
  }
}
