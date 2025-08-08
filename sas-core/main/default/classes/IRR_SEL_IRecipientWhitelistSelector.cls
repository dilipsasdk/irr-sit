/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*/

public interface IRR_SEL_IRecipientWhitelistSelector extends fflib_ISObjectSelector {
    Set<String> getAllWhitelistedRecipients();
}