/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*/

public interface IRR_SEL_IDelayLogsSelector extends fflib_ISObjectSelector {
    Map<String, Integer> getLatestDelayByFlightIds(Set<String> flightIds);
    Integer getDelayByFlightIds(Set<String> flightIds);
}