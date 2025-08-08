/**
 * @author Chetan Singh, Coforge
 * @date 2020
 *
 * @description Model Class for Teds API callout responses.
 *      Contains parse methods for deserialization of JSON.
 */

 public class IRR_MOD_TedsBooking {
  public String id { get; set; }
  public String reference { get; set; }
  public String type { get; set; }
  public String status { get; set; }
  public Boolean isCancelled { get; set; }
  public String codsId { get; set; }
  public Audit audit { get; set; }
  public List<Passenger> passengers { get; set; }
  public List<Passenger> segments { get; set; }
  public List<Trip> trips { get; set; }
  public Boolean isGroupBooking { get; set; }
  public GroupInfo groupInfo { get; set; }
  public class Arrival {
    public String station { get; set; }
    public ScheduledTime scheduledTime { get; set; }
  }

  public class Audit {
    public Created created { get; set; }
    public Updated updated { get; set; }
  }

  public class Baggage {
    public Quantity quantity { get; set; }
  }

  public class CheckIn {
    public String status { get; set; }
    public String channel { get; set; }
  }

  public class Contact {
    public List<Phone> phone { get; set; }
    public List<Email> email { get; set; }
  }

  public class Created {
    public String officeId { get; set; }
    public String at { get; set; }
  }

  public class Departure {
    public String station { get; set; }
    public ScheduledTime scheduledTime { get; set; }
    public String terminal { get; set; }
  }

  public class Email {
    public String type { get; set; }
    public String address { get; set; }
    public String ssrId { get; set; }
  }

  public class EuroBonus {
    public List<String> segmentIds { get; set; }
    public String number_x { get; set; }
    public String tier { get; set; }
  }
public class Tier {
  public String level { get; set; }
  public String description { get; set; }

}
  



  public class Fare {
    public String basis { get; set; }
  }

  public class Flight {
    public String id { get; set; }
    public String operatingId { get; set; }
    public String operatingCarrier { get; set; }
    public String operatingFlightNumber { get; set; }
    public String marketingCarrier { get; set; }
    public String marketingFlightNumber { get; set; }
    public Departure departure { get; set; }
    public Arrival arrival { get; set; }
  }

  public class FrequentTraveler {
    public List<EuroBonus> euroBonus { get; set; }
    public List<OtherFQTV> other { get; set; }
    Public String carrier{get;set;}
    public Tier tier { get; set; }
  }

  public class Passenger {
    public String id { get; set; }
    public String firstName { get; set; }
    public String lastName { get; set; }
    public Contact contact { get; set; }
    public String title { get; set; }
    public FrequentTraveler frequentTraveler { get; set; }
    public List<SpecialServiceRequests> specialServiceRequests { get; set; }
    public List<Segment> segments { get; set; }
  }

  public class Phone {
    public String type { get; set; }
    public String number_x { get; set; }
  }

  public class ScheduledTime {
    public String utc { get; set; }
    public String local { get; set; }
  }

  public class Segment {
    // Added by Gaurav for Icoupon
    public Integer boardingSequenceNumber { get; set; }
    public String segmentId { get; set; }
    public Baggage baggage { get; set; }
    public CheckIn checkin { get; set; }
    public Fare fare { get; set; }
    public Boolean isBoarded { get; set; }
    public String seat { get; set; }
    public Ticket ticket { get; set; }
  }

  public class SpecialServiceRequests {
    public List<String> segmentIds { get; set; }
    public String type { get; set; }
    public String code { get; set; }
    public String text { get; set; }
    public List<FrequentTraveler> frequentTraveler { get; set; }
    
  }

  public class SegmentTrip {
    public String id { get; set; }
    public String statusCode { get; set; }
    public String status { get; set; }
    public String transportationType { get; set; }
    public Flight flight { get; set; }
    public String bookingClass { get; set; }
    public String serviceClass { get; set; }
    public List<Remark> remarks { get; set; }
  }
  public class Remark {
    public String type { get; set; }
    public String value { get; set; }
}

  public class OtherFQTV {
    public List<String> segmentIds { get; set; }
    public String number_x { get; set; }
    public String carrier { get; set; }
  }

  public class Quantity {
    public Integer allowed { get; set; }
    public Integer extra { get; set; }
  }

  public class Ticket {
    public String number_x { get; set; }
    public String type { get; set; }
  }

  public class Trip {
    public String type { get; set; }
    public List<SegmentTrip> segments { get; set; }
  }

  public class Updated {
    public String officeId { get; set; }
    public String at { get; set; }
  }
    
  public class GroupInfo {
    public String name { get; set; }
    public Contact contact { get; set; }
  }   
    
    

  private static final Map<String, String> replacementMap = new Map<String, String>{
    'number' => 'number_x',
    'group' => 'GroupInfo'   
  };

    public static IRR_MOD_TedsBooking parse(String json) {
        ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
                IRR_MOD_TedsBooking.class, replacementMap);
        return (IRR_MOD_TedsBooking) jsonDeserializer.deserialize(json);
    }

    public static List<IRR_MOD_TedsBooking> parseArray(String json) {
        ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
                List<IRR_MOD_TedsBooking>.class, replacementMap);
        return (List<IRR_MOD_TedsBooking>) jsonDeserializer.deserialize(json);
    }

}