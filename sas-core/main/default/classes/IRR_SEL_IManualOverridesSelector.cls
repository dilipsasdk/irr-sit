/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*/

public interface IRR_SEL_IManualOverridesSelector extends fflib_ISObjectSelector {
    List<IRR_ManualOverride__c> selectActiveManualOverridesByFlightId(String flightId);
}