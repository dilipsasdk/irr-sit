/**
 * Routes and sets the priority of a single Case
 */
public without sharing class RouteCaseAndSetPriority {
  @InvocableMethod(label='Route Case And Set Priority')
  public static void routeAndSetPriority(List<Id> caseToRoute) {
    CaseService.assignPriorityAndRouteToQueue(new Set<Id>(caseToRoute));
  }
}
