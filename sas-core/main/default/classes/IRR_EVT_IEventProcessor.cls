/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*/

public interface IRR_EVT_IEventProcessor {
    void initiateEvent();
    void validateEvent();
    Boolean checkActiveBlock();
    void processEvent();
    void processMessages();
    void finalizeEvent(fflib_ISObjectUnitOfWork uow);
}