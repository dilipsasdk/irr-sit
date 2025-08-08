public without sharing class FlightIrregularities extends ApplicationDomain {
  public FlightIrregularities(List<SObject> records) {
    super(records);
    this.instanceRecords = (List<FlightIrregularities__c>) Records;
  }
  public List<FlightIrregularities__c> instanceRecords;
  public Map<String, List<FlightIrregularities__c>> TEDSIdToIrregularities = new Map<String, List<FlightIrregularities__c>>{};

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> records) {
      return new FlightIrregularities(records);
    }
  }

  public override void onBeforeInsert() {
    setEligibility();
  }

  public static FlightIrregularities newInstance(
    List<FlightIrregularities__c> sObjectList
  ) {
    return (FlightIrregularities) SAS_Service_Application.Domain.newInstance(
      sObjectList
    );
  }

  public void setEligibility() {
    for (FlightIrregularities__c irr : instanceRecords) {
      FlightIrregularity fi = new FlightIrregularity(irr);
      fi.setEligibility();
      fi.updateSObjectFields();
    }
  }

  /**
   * Creates flight irregularities from TEDS data.
   * @param TEDSIds A List of Strings of TEDSIds
   * @param TEDSIdToflightArrivals A Map<String, TEDSFlight.Arrival> which maps the TEDSId of the flight to the Arrival information from TEDS
   * @param TEDSIdToflightDepartures A Map<String, TEDSFlight.Departure> which maps the TEDSId of the flight to the Departure information from TEDS
   * @return A Flightirregularities object created from the TEDS data.
   */
  public static FlightIrregularities createFromTEDSData(
    List<String> TEDSIds,
    Map<String, TEDSFlight.Arrival> TEDSIdToflightArrivals,
    Map<String, TEDSFlight.Departure> TEDSIdToflightDepartures
  ) {
    List<FlightIrregularities__c> processedIrregularities = new List<FlightIrregularities__c>{};
    Map<String, List<FlightIrregularities__c>> TEDSIdToIrregularities = new Map<String, List<FlightIrregularities__c>>{};
    for (String TEDSId : TEDSIds) {
      List<FlightIrregularities__c> flightSpecificIrregularities = new List<FlightIrregularities__c>{};
      TEDSFlight.Arrival arrival = TEDSIdToflightArrivals.get(TEDSId);
      TEDSFlight.Departure departure = TEDSIdToflightDepartures.get(TEDSId);

      if (arrival != null) {
        if (arrival.status == 'delayed') {
          flightSpecificIrregularities.addAll(
            createFlightIrregularityFromDelay(arrival.delayReasons, '(arrival)')
          );
        } else if (arrival.status == 'cancelled') {
          flightSpecificIrregularities.addAll(
            createFlightIrregularityFromCancellation(
              arrival.cancellationReasons,
              '(arrival)',
              null
            )
          );
        }
      }
      if (departure != null) {
        if (departure.status == 'delayed') {
          flightSpecificIrregularities.addAll(
            createFlightIrregularityFromDelay(
              departure.delayReasons,
              '(departure)'
            )
          );
        } else if (departure.status == 'cancelled') {
          flightSpecificIrregularities.addAll(
            createFlightIrregularityFromCancellation(
              departure.cancellationReasons,
              '(departure)',
              departure.cancellationTime
            )
          );
        }
      }
      TEDSIdToIrregularities.put(TEDSId, flightSpecificIrregularities);
      processedIrregularities.addAll(flightSpecificIrregularities);
    }

    FlightIrregularities newFlightIrregularities = FlightIrregularities.newInstance(
      processedIrregularities
    );
    newFlightIrregularities.TEDSIdToIrregularities = TEDSIdToIrregularities;

    return newFlightIrregularities;
  }

  public class FlightsAreMissingIdsException extends Exception {
  }

  /**
   * This function has to be called before insertion, otherwise the insert throws an exception
   * @return Returns "this" to enable chaining
   */
  public FlightIrregularities addFlightReferences(List<Flight__c> flights) {
    for (Flight__c flight : flights) {
      List<FlightIrregularities__c> irregularities = TEDSIdToIrregularities.get(
        flight.TEDS_Identifier__c
      );
      if (irregularities != null) {
        for (FlightIrregularities__c irregularity : irregularities) {
          Id flightId = flight.Id;
          if (flightId == null) {
            throw new FlightsAreMissingIdsException(
              'The flights which the irregularities reference do not have Ids. Please insert the flights into the database before calling this function.'
            );
          }
          irregularity.Flight__c = flightId;
        }
      }
    }

    return this;
  }

  /**
   * Deprecated, left here in case Liability decides we can use the logic once more.
   *
   * The issue is due to a court case where the reason for the CREW-cancellation was
   * the sudden death of a pilot. The court decided that this was not extraordinary,
   * despite the fact that the flight was from a small airport.
   */
  public FlightIrregularities setEU261EligibilityForCREWIrregularities() {
    Set<Id> crewFlightIds = new Set<Id>();
    List<FlightIrregularities__c> crewIrregs = new List<FlightIrregularities__c>();

    for (FlightIrregularities__c fi : instanceRecords) {
      if (fi.Code__c == 'CREW') {
        crewFlightIds.add(fi.Flight__c);
        crewIrregs.add(fi);
      }
    }

    List<Flight__c> crewFlights = FlightsSelector.newInstance()
      .selectById(crewFlightIds);

    Map<Id, Flight__c> idToFlight = new Map<Id, Flight__c>(crewFlights);

    for (FlightIrregularities__c fi : crewIrregs) {
      Flight__c irrFlight = idToFlight.get(fi.Flight__c);
      Flight f = new Flight(irrFlight);
      if (f.departsHub()) {
        fi.Eligible_For_EU261__c = 'Yes';
      }
    }

    return this;
  }

  public Map<Id, List<FlightIrregularities__c>> getFlightIdToIrregularities() {
    Map<Id, List<FlightIrregularities__c>> flightIdToIrregularities = new Map<Id, List<FlightIrregularities__c>>();
    for (FlightIrregularities__c irregularity : instanceRecords) {
      List<FlightIrregularities__c> currentIrregularities = flightIdToIrregularities.get(
        irregularity.Flight__c
      );
      if (currentIrregularities == null) {
        flightIdToIrregularities.put(
          irregularity.Flight__c,
          new List<FlightIrregularities__c>{ irregularity }
        );
      } else {
        currentIrregularities.add(irregularity);
      }
    }
    return flightIdToIrregularities;
  }

  /**
   * Creates FlightIrregularities__c of type "Delay" from TEDS data.
   * @param reasons A list of TEDSFlight.DelayReasons from which the FlightIrregularities__c should be created.
   * @param additionalInfo A String with additional info to add to the type of the irregularity, either: "(arrival)" or "(departure)".
   * @return A List of the FlightIrregularities__c created from the TEDS data.
   */
  private static List<FlightIrregularities__c> createFlightIrregularityFromDelay(
    List<TEDSFlight.DelayReasons> reasons,
    String additionalInfo
  ) {
    List<FlightIrregularities__c> result = new List<FlightIrregularities__c>{};
    String eligibleForEU261;
    if (reasons != null) {
      for (TEDSFlight.DelayReasons reason : reasons) {
        String code = 'N/A';
        String reasonText = reason.reasonText;
        if (reason.reasonCode != null) {
          code = reason.reasonCode;
        }
        if (reasonText?.length() > 2000) {
          reasonText = reasonText.substring(0, 2000);
        }
        if (FlightIrregularity.codeToSASIsResponsible.get(code) == null) {
          eligibleForEU261 = 'Tentative';
        } else if (FlightIrregularity.codeToSASIsResponsible.get(code)) {
          eligibleForEU261 = 'Yes';
        } else {
          eligibleForEU261 = 'No';
        }

        result.add(
          new FlightIrregularities__c(
            Code__c = code,
            Duration_minutes__c = DateUtils.convertISO8601DurationToMinutes(
              reason.duration
            ),
            Reason__c = reasonText,
            Type__c = 'Delay ' + additionalInfo,
            Eligible_For_EU261__c = eligibleForEU261
          )
        );
      }
    } else {
      // Delayed no reason
      result.add(
        new FlightIrregularities__c(
          Code__c = 'N/A',
          Reason__c = '',
          Type__c = 'Delay ' + additionalInfo,
          Eligible_For_EU261__c = 'Tentative'
        )
      );
    }
    return result;
  }

  /**
   * Creates FlightIrregularities__c of type "Cancellation" from TEDS data.
   * @param reasons A list of TEDSFlight.CancellationReasons from which the FlightIrregularities__c should be created.
   * @param additionalInfo A String with additional info to add to the type of the irregularity, either: "(arrival)" or "(departure)".
   * @return A List of the FlightIrregularities__c created from the TEDS data.
   */
  private static List<FlightIrregularities__c> createFlightIrregularityFromCancellation(
    List<TEDSFlight.CancellationReasons> reasons,
    String additionalInfo,
    String isoCancellationTime
  ) {
    List<FlightIrregularities__c> result = new List<FlightIrregularities__c>{};
    String eligibleForEU261;
    if (reasons != null) {
      for (TEDSFlight.CancellationReasons reason : reasons) {
        String code = 'N/A';
        String reasonText = reason.supplementaryInformation;
        Datetime cancellationTime;
        if (reason.reasonCode != null) {
          code = reason.reasonCode;
        }
        if (reasonText?.length() > 2000) {
          reasonText = reasonText.substring(0, 2000);
        }
        if (isoCancellationTime != null) {
          try {
            cancellationTime = DateUtils.isoDatetimeToApexDateTime(
              isoCancellationTime
            );
          } catch (Exception e) {
          }
        }
        if (FlightIrregularity.codeToSASIsResponsible.get(code) == null) {
          eligibleForEU261 = 'Tentative';
        } else if (FlightIrregularity.codeToSASIsResponsible.get(code)) {
          eligibleForEU261 = 'Yes';
        } else {
          eligibleForEU261 = 'No';
        }
        result.add(
          new FlightIrregularities__c(
            Code__c = code,
            Reason__c = reasonText,
            Type__c = 'Cancellation ' + additionalInfo,
            Cancellation_Time__c = cancellationTime,
            Eligible_For_EU261__c = eligibleForEU261
          )
        );
      }
    } else {
      // Cancelled no reason
      result.add(
        new FlightIrregularities__c(
          Code__c = 'N/A',
          Reason__c = '',
          Type__c = 'Cancellation ' + additionalInfo,
          Eligible_For_EU261__c = 'Tentative'
        )
      );
    }
    return result;
  }
}
