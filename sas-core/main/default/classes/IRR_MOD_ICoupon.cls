public class IRR_MOD_ICoupon {

  public String airportCode { get; set; }
  public String causingAirlineCode { get; set; }
  public Integer causingFlightNumber { get; set; }
  public String causingFlightDate { get; set; }
  public Integer voucherValue { get; set; }
  public String reasonComment { get; set; }
  public RedemptionPassDetails redemptionPassDetails{get;set;}
  public class RedemptionPassDetails {
  public String airlineCode { get; set; }
  public Integer flightNumber { get; set; }
  public String flightDate { get; set; }
  public List<String> boardingSequences { get; set; }
  public String voucherProfile {get; set; }
  public String airportList {get; set;}
  }
}