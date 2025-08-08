public without sharing class FeedbackService {
  public class FeedbackException extends Exception {
  }

  private static Map<String, String> feedbackTypeMapping = new Map<String, String>{
    'accessibility-barrier' => 'Accessibility barrier',
    'sas-accessibility-plan' => 'SAS\' accessibility plan',
    'other-issues' => 'Other issues'
  };

  public static String createCaseWithFeedback(CreateFeedbackRequest request) {
    Case newCase = createCaseRecord(request);

    Database.DMLOptions dmlOptions = new Database.DMLOptions();
    dmlOptions.EmailHeader.triggerAutoResponseEmail = true;
    database.insert(newCase, dmlOptions);

    Case insertedCase = CasesSelector.newInstance().selectById(new Set<Id>{ newCase.Id })[0];

    return insertedCase.CaseNumber;
  }

  private static Case createCaseRecord(CreateFeedbackRequest request) {
    Id liabilityQueueId = GroupsSelector.newInstance().selectQueuesByDepartment(new Set<String>{ 'Liability' })[0].Id;

    Case newCase = new Case(
      OwnerId = liabilityQueueId,
      Origin = request.origin,
      SuppliedEmail = request.feedback.email,
      Subject = 'Passengers With Disability CA EN',
      Feedback_Type__c = request.feedback.feedbackType != null ? feedbackTypeMapping.get(request.feedback.feedbackType) : '',
      Feedback_Area__c = request.feedback.area,
      Feedback_Comment__c = request.feedback.comment,
      Priority = 'High',
      RecordTypeId = Cases.getRecordTypeId(Cases.RecordType.Channel)
    );

    return newCase;
  }
}
