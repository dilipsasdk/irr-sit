public without sharing class CreateFeedbackRequest {
  public Feedback feedback { get; private set; }
  public String origin { get; private set; }

  public class InvalidDataException extends Exception {
  }

  private static Map<String, String> areaMapping = new Map<String, String>{
    'technology' => 'Technology (website, app, booking, etc.)',
    'information' => 'Information (emails, text messages, signage at the airport, etc.)',
    'services' => 'Services and products (pre booked travel extras, booking experience, etc.)',
    'transportation' => 'Transportation (ground assistance, onboard assistance, onboard safety, etc.)',
    'aircraft' => 'The built environment related to the aircraft (seats, toilets, onboard wheelchair storage, etc.)',
    'terminal' => 'The built environment related to passenger terminals (toilets, ramps, elevators, signage, check-in area, gate, etc.)',
    'other' => 'Other'
  };

  public class Feedback {
    public String feedbackType { get; private set; }
    public String area { get; private set; }
    public String comment { get; private set; }
    public String email { get; private set; }

    public Feedback(CaseFormJSONV2.Feedback jsonData) {
      feedbackType = jsonData.feedbackType;
      area = '';
      if (jsonData.area != null && jsonData.area.size() > 0) {
        for (String oneArea : jsonData.area) {
          area += '- ' + areaMapping.get(oneArea) + '\r\n' ;
        }
      }
      area = area.trim();
      comment = jsonData.comment.trim();
      email = jsonData.email;
    }
  }

  public CreateFeedbackRequest(CaseFormJSONV2 jsonData) {
    feedback = new Feedback(jsonData.formData.feedback);
    origin = 'Form - Passengers With Disability CA EN';
  }
}