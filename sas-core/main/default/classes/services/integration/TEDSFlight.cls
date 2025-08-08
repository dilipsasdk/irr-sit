/**
 * Data structure and parser for TEDS Flight API v2 data
 */
public class TEDSFlight {
  public String id { get; set; }
  public String carrier { get; set; }
  public String flightNumber { get; set; }
  public String callSign { get; set; }
  public ServiceType serviceType { get; set; }
  public Arrival arrival { get; set; }
  public Departure departure { get; set; }
  public Aircraft aircraft { get; set; }
  public PassengerCapacity passengerCapacity { get; set; }

  public class Aircraft {
    public String type { get; set; }
    public String registration { get; set; }
  }

  public class PassengerCapacity {
    public Integer C { get; set; }
    public Integer Y { get; set; }
    public Integer M { get; set; }
  }

  public class ServiceType {
    public String code { get; set; }
    public String application { get; set; }
  }

  public class Arrival {
    public Integer delayedMinutes { get; set; }
    public String gate { get; set; }
    public TimeInfo actualTime { get; set; }
    public TimeInfo estimatedTime { get; set; }
    public TimeInfo scheduledTime { get; set; }
    public String station { get; set; }
    public String status { get; set; }
    public Terminal terminal { get; set; }
    public List<DelayReasons> delayReasons { get; set; }
    public List<CancellationReasons> cancellationReasons { get; set; }
  }

  public class Departure {
    public Integer delayedMinutes { get; set; }
    public String gate { get; set; }
    public TimeInfo actualTime { get; set; }
    public TimeInfo estimatedTime { get; set; }
    public TimeInfo scheduledTime { get; set; }
    public String station { get; set; }
    public String status { get; set; }
    public Terminal terminal { get; set; }
    public List<DelayReasons> delayReasons { get; set; }
    public List<CancellationReasons> cancellationReasons { get; set; }
    public String cancellationTime { get; set; }
  }

  public class Terminal {
    public String id { get; set; }
    public String description { get; set; }
  }

  public class TimeInfo {
    public String utc { get; set; }
    public String local { get; set; }
  }

  public class DelayReasons {
    public String reasonText { get; set; }
    public String subReasonCode { get; set; }
    public String duration { get; set; }
    public String reasonCode { get; set; }
  }

  public class CancellationReasons {
    public String reasonCode { get; set; }
    public String supplementaryInformation { get; set; }
  }

  private static final Map<String, String> REPLACEMENT_MAP = new Map<String, String>{
    'number' => 'number_x'
  };

  public static TEDSFlight parse(String json) {
    
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      TEDSFlight.class,
      REPLACEMENT_MAP
    );
    return (TEDSFlight) jsonDeserializer.deserialize(json);
  }

  public static List<TEDSFlight> parseArray(String json) {
    ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
      List<TEDSFlight>.class,
      REPLACEMENT_MAP
    );
    return (List<TEDSFlight>) jsonDeserializer.deserialize(json);
  }
}