/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Entry point for Teds integration functionality.
*/

public class IRR_SVC_TedsService {

    public static final String TICKET_IDENTIFIER_SAS = '117-';
    public static final String TICKET_IDENTIFIER_WIDEROE = '701-';

    public static final String BOOKING_STATUS_CONFIRMED = 'Confirmed';

    public static List<IRR_MOD_PassengerInfo> getPassengerInfosForBooking(String bookingId) {
        return service().getPassengerInfosForBooking(bookingId);
    }

    public static List<IRR_MOD_PassengerInfo> getPassengerInfosForFlight(String flightId) {
        return service().getPassengerInfosForFlight(flightId);
    }

    public static List<IRR_MOD_PassengerInfo> getPassengerInfosForBookingFilters(String departureStation, String arrivalStation,String fromTimeUTC,String toTimeUTC) {
        return service().getPassengerInfosForBookingFilters(departureStation,arrivalStation,fromTimeUTC,toTimeUTC);
    }

    public static Map<String,String> getAirportCityNames(Set<String> iataCodes) {
        return service().getAirportCityNames(iataCodes);
    }

    public static List<TEDSFlight> getFlightInfos(String flightId) {
        return service().getFlightInfos(flightId);
    }

    private static IRR_SVC_ITedsService service() {
        return (IRR_SVC_ITedsService) IRR_Application.Service.newInstance(IRR_SVC_ITedsService.class);
    }

    public class TedsException extends Exception { }
}