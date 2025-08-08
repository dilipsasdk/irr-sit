@IsTest
public with sharing class TestIrregularityFactory {
  public static FlightIrregularity createCancellation(Flight f) {
    FlightIrregularity fi = new FlightIrregularity(
      new FlightIrregularities__c()
    );

    fi.id = fflib_IDGenerator.generate(
      FlightIrregularities__c.getSObjectType()
    );
    fi.cancellationTime = DateTime.newInstance(2020, 1, 1, 1, 1, 1);
    fi.code = 'TECH';
    fi.description = null;
    fi.durationMinutes = 60;
    fi.eligibleForEU261 = FlightIrregularity.EU261Eligibility.Yes;
    fi.flightId = f.id;
    fi.reason = 'Plane damaged';
    fi.type = 'Cancellation (departure)';

    return fi;
  }

  public static FlightIrregularity createDelay(
    Flight f,
    String code,
    Integer durationMinutes
  ) {
    FlightIrregularity fi = new FlightIrregularity(
      new FlightIrregularities__c()
    );

    fi.id = fflib_IDGenerator.generate(
      FlightIrregularities__c.getSObjectType()
    );
    fi.code = code;
    fi.description = null;
    fi.durationMinutes = durationMinutes;
    Boolean canDetermineEligibility = FlightIrregularity.codeToSASIsResponsible.get(
      code
    );
    if (canDetermineEligibility == null) {
      fi.eligibleForEU261 = FlightIrregularity.EU261Eligibility.Tentative;
    } else {
      fi.eligibleForEU261 = canDetermineEligibility
        ? FlightIrregularity.EU261Eligibility.Yes
        : FlightIrregularity.EU261Eligibility.No;
    }
    fi.flightId = f.id;
    fi.reason = '';
    fi.type = 'Delay (departure)';

    return fi;
  }

  public static FlightIrregularity createDefaultDelay(Flight f) {
    FlightIrregularity fi = new FlightIrregularity(
      new FlightIrregularities__c()
    );

    fi.id = fflib_IDGenerator.generate(
      FlightIrregularities__c.getSObjectType()
    );
    fi.code = 'FA';
    fi.description = null;
    fi.durationMinutes = 180;
    fi.eligibleForEU261 = FlightIrregularity.EU261Eligibility.Yes;
    fi.flightId = f.id;
    fi.reason = 'Special request caused issues';
    fi.type = 'Delay (departure)';

    return fi;
  }
}
