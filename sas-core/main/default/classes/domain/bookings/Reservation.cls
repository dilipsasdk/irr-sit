public without sharing abstract class Reservation {
  public Booking booking { get; protected set; }
  public Map<String, Flight> flights { get; protected set; }

  @SuppressWarnings('PMD.EmptyStatementBlock')
  protected Reservation() {
  }

  protected abstract Booking constructBookingFromSourceData(Object sourceData);
  protected abstract List<Passenger> constructPassengersFromSourceData(
    List<Object> sourceData
  );

  protected abstract List<Segment> constructSegmentsFromSourceData(
    List<Object> sourceData
  );

  protected abstract Map<String, Flight> constructFlightsFromSourceData(
    List<Object> sourceData
  );

  public Integer getBookingSize() {
    Integer size = 0;
    size += booking.passengers.size();
    for (Flight f : booking.flights) {
      if (f.irregularities == null) {
        continue;
      }
      size += f.irregularities.size();
    }
    size += booking.flights.size();
    for (Segment s : this.booking.segments) {
      if (s.getEvents() == null) {
        continue;
      }
      size += s.getEvents().size();
    }
    size += booking.segments.size();
    return size;
  }
}
