/**
 * Trigger used to process events from Marketing Cloud Event Notficiation Service
 * The trigger will attempt to update all the referenced messages of the provided message keys
 * If some message keys cannot be found the trigger throws a retry exception until the message is older than 3 minutes
 * to ensure that the event is not processed prior to the message having been stored in the database.
 * @author Peter Södergren
 */
trigger MCENS_EnsEventTrigger on MCENS_EnsEvent__e (after insert) {
    EventBus.TriggerContext ctx = EventBus.TriggerContext.currentContext();
    MCENS_EnsEventTriggerHandler handler = new MCENS_EnsEventTriggerHandler(Trigger.new,ctx.retries,ctx.lastError);
    handler.run();
    EventBus.TriggerContext.currentContext().setResumeCheckpoint(handler.getLastReplayId());
}