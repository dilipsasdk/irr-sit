/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description TODO
*/

public interface IRR_DOM_ICommunicationLogs extends fflib_ISObjectDomain {
    void processGDPRLogs(fflib_ISObjectUnitOfWork uow, DateTime lastRetentionDate);
}