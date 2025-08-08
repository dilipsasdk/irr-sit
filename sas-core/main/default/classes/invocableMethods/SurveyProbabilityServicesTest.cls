@IsTest
public class SurveyProbabilityServicesTest {
  @IsTest
  static void getSurveyProbabilityServicesTest() {
      List<Integer> percentages = new List<Integer>();
      percentages.add(50);
      SurveyProbabilityServices.getSurveyProbabilityServices(percentages);
  }
}