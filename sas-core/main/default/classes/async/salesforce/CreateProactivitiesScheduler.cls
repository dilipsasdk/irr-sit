public with sharing class CreateProactivitiesScheduler implements Schedulable {
  public void execute(SchedulableContext jobId) {
    List<Flight__c> flights = FlightsSelector.newInstance()
      .selectFlightsWhichShouldHaveLandedTheLast24Hours();
    Set<Id> flightIds = new Map<Id, Flight__c>(flights).keySet();
    ProactivityService.createAutomationProactivitiesFromFlightIds(flightIds);
  }
}
