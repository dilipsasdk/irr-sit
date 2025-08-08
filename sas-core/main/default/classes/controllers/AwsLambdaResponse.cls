public class AwsLambdaResponse {

	public String userId;
	public Boolean success;
	
	public static List<AwsLambdaResponse> parse(String json) {
		return (List<AwsLambdaResponse>) System.JSON.deserialize(json, List<AwsLambdaResponse>.class);
	}
    
}