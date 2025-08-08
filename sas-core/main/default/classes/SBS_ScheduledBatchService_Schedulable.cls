/**
    Schedulable class used to run a scheduled batch run
    for a specific time segment
    @author Peter Södergren
*/
global with sharing class SBS_ScheduledBatchService_Schedulable implements Schedulable, Database.AllowsCallouts{
    /**
        The time segment of batches which should be triggered to run
    */
    private String timeSegment;
    /**
        Creates a schedulable instance for a specific time segment
        @param timeSegment The time segment of batches which should be triggered to run
    */
    global SBS_ScheduledBatchService_Schedulable(String timeSegment) {
        this.timeSegment = timeSegment;
    }
    /**
		Starts the scheduled batch service for the specific time segment
		@param sc The schedulable context
	*/
	global void execute(SchedulableContext sc) {
		SBS_ScheduledBatchService.run(timeSegment);
	}
}
