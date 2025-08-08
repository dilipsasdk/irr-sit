/**
    Class invoked by a process to remove additional survey responses. Deletes all completed responses but the first.
    @author Philip Ossler
*/
public without sharing class FCS_RemoveAdditionalSurveyResponses {
  @InvocableMethod(
    label='Remove Additional SurveyResponses'
    description='Only the first SurveyResponse per Case will be saved'
  )
  /**
        @param invitationId The Id of related Survey Invitation
    */
  public static void updateSurveyResponses(List<Id> invitationId) {
    List<SurveyResponse> surveyResponses = [
      SELECT Id, InvitationId, Status
      FROM SurveyResponse
      WHERE InvitationId IN :invitationId
      ORDER BY Status DESC, CreatedDate ASC
    ];
    Set<Id> recordsBySurveyInvitation = new Set<Id>();
    List<SurveyResponse> recordsToRemove = new List<SurveyResponse>();
    for (SurveyResponse sr : surveyResponses) {
      if (
        !recordsBySurveyInvitation.contains(sr.InvitationId) &&
        sr.Status == 'Completed' || sr.Status == 'Started'
      ) {
        recordsBySurveyInvitation.add(sr.InvitationId);
      } else {
        recordsToRemove.add(sr);
      }
    }
    delete recordsToRemove;
  }
}
