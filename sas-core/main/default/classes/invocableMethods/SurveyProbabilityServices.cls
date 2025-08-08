public class SurveyProbabilityServices {
    @InvocableMethod(label='SurveyProbabilityServices')
    public static List<Boolean> getSurveyProbabilityServices(List<Integer> percentages) {
        //Validate the input percentage
        Integer percentage = !percentages.isEmpty() ? Integer.valueOf(percentages[0]) : 100;
        if (percentage < 0 || percentage > 100) {
            throw new IllegalArgumentException('Percentage must be between 0 and 100 (inclusive).');
        }
        Integer randomValue = (Integer)(Math.random() * 100);
        Boolean flag = randomValue < percentage;
        List<Boolean> flagList = new List<Boolean>();
        flagList.add(flag);
        return flagList;
    }
}