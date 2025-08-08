/**
* @author Chetan Singh, CoforgeTech
* @date 2020
*
* @description Model Class for Teds Airport API callout responses.
 *      Contains parse methods for deserialization of JSON.
*/
public with sharing class IRR_MOD_AirportInfo {
    
	public String id;
	public String name;
	public String city;
	public Country country;
	public Coordinates coordinates;

	public class Coordinates {
		public String latitude;
		public String longitude;
	}

	public class Country {
		public String code;
		public String name;
    }
    private static final Map<String, String> replacementMap = new Map<String, String>{
        'number' => 'number_x'
};

	public static List<IRR_MOD_AirportInfo> parseArray(String json) {
        ffhttp_JsonDeserializer jsonDeserializer = new ffhttp_JsonDeserializer(
                List<IRR_MOD_AirportInfo>.class, replacementMap);
        return (List<IRR_MOD_AirportInfo>) jsonDeserializer.deserialize(json);
    }
	
}

