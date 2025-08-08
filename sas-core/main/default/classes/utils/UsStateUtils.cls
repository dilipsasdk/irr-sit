/**
 * Utility class which handles US States
 */
public without sharing class UsStateUtils {
  public static String getStateFromPostalCode(String zipCode) {
    String state;
    if (String.isEmpty(zipCode) || !(zipCode.isNumeric())) {
      state = null;
    } else {
      Integer postalCode = integer.valueof(zipCode);
      //States for given postalCode according to the source https://www.zipcode.com.ng/2022/06/list-of-5-digit-zip-codes-united-states.html

      if (postalCode >= 35004 && postalCode <= 36925) {
        state = 'Alabama';
      } else if (postalCode >= 99501 && postalCode <= 99950) {
        state = 'Alaska';
      } else if (postalCode >= 85001 && postalCode <= 86556) {
        state = 'Arizona';
      } else if (postalCode >= 71601 && postalCode <= 72959) {
        state = 'Arkansas';
      } else if (postalCode >= 90001 && postalCode <= 96162) {
        state = 'California';
      } else if (postalCode >= 80001 && postalCode <= 81658) {
        state = 'Colorado';
      } else if (postalCode >= 6001 && postalCode <= 6928) {
        state = 'Connecticut';
      } else if (postalCode >= 19701 && postalCode <= 19980) {
        state = 'Delaware';
      } else if (postalCode >= 32003 && postalCode <= 34997) {
        state = 'Florida';
      } else if (postalCode >= 30002 && postalCode <= 39901) {
        state = 'Georgia';
      } else if (postalCode >= 96701 && postalCode <= 96898) {
        state = 'Hawaii';
      } else if (postalCode >= 83201 && postalCode <= 83877) {
        state = 'Idaho';
      } else if (postalCode >= 60001 && postalCode <= 62999) {
        state = 'Illinois';
      } else if (postalCode >= 46001 && postalCode <= 46997) {
        state = 'Indiana';
      } else if (postalCode >= 50001 && postalCode <= 52809) {
        state = 'Iowa';
      } else if (postalCode >= 66002 && postalCode <= 67954) {
        state = 'Kansas';
      } else if (postalCode >= 40003 && postalCode <= 42788) {
        state = 'Kentucky';
      } else if (postalCode >= 70001 && postalCode <= 71497) {
        state = 'Louisiana';
      } else if (postalCode >= 3901 && postalCode <= 4992) {
        state = 'Maine';
      } else if (postalCode >= 20588 && postalCode <= 21930) {
        state = 'Maryland';
      } else if (postalCode >= 1001 && postalCode <= 5544) {
        state = 'Massachusetts';
      } else if (postalCode >= 48001 && postalCode <= 49971) {
        state = 'Michigan';
      } else if (postalCode >= 55001 && postalCode <= 56763) {
        state = 'Minnesota';
      } else if (postalCode >= 38601 && postalCode <= 39776) {
        state = 'Mississippi';
      } else if (postalCode >= 63001 && postalCode <= 65899) {
        state = 'Missouri';
      } else if (postalCode >= 59001 && postalCode <= 59937) {
        state = 'Montana';
      } else if (postalCode >= 68001 && postalCode <= 69367) {
        state = 'Nebraska';
      } else if (postalCode >= 88901 && postalCode <= 89883) {
        state = 'Nevada';
      } else if (postalCode >= 3031 && postalCode <= 3897) {
        state = 'New Hampshire';
      } else if (postalCode >= 7001 && postalCode <= 8989) {
        state = 'New Jersey';
      } else if (postalCode >= 87001 && postalCode <= 88439) {
        state = 'New Mexico';
      } else if (
        (postalCode >= 10000 &&
        postalCode <= 14925) ||
        (postalCode == 6390) ||
        (postalCode == 501) ||
        (postalCode == 544)
      ) {
        state = 'New York';
      } else if (postalCode >= 27006 && postalCode <= 28909) {
        state = 'North Carolina';
      } else if (postalCode >= 58001 && postalCode <= 58856) {
        state = 'North Dakota';
      } else if (postalCode >= 43001 && postalCode <= 45999) {
        state = 'Ohio';
      } else if (postalCode >= 73001 && postalCode <= 74966) {
        state = 'Oklahoma';
      } else if (postalCode >= 97001 && postalCode <= 97920) {
        state = 'Oregon';
      } else if (postalCode >= 15001 && postalCode <= 19640) {
        state = 'Pennsylvania';
      } else if (postalCode >= 2801 && postalCode <= 2940) {
        state = 'Rhode Island';
      } else if (postalCode >= 29001 && postalCode <= 29945) {
        state = 'South Carolina';
      } else if (postalCode >= 57001 && postalCode <= 57799) {
        state = 'South Dakota';
      } else if (postalCode >= 37010 && postalCode <= 38589) {
        state = 'Tennessee';
      } else if (postalCode >= 73301 && postalCode <= 88595) {
        state = 'Texas';
      } else if (postalCode >= 84001 && postalCode <= 84091) {
        state = 'Utah';
      } else if (postalCode >= 5001 && postalCode <= 5907) {
        state = 'Vermont';
      } else if (postalCode >= 20101 && postalCode <= 24658) {
        state = 'Virginia';
      } else if (postalCode >= 98001 && postalCode <= 99403) {
        state = 'Washington';
      } else if (postalCode >= 24701 && postalCode <= 26886) {
        state = 'West Virginia';
      } else if (postalCode >= 53001 && postalCode <= 54990) {
        state = 'Wisconsin';
      } else if (postalCode >= 82001 && postalCode <= 83414) {
        state = 'Wyoming';
        //Territories of US
      } else if (postalCode == 96799) {
        state = 'American Samoa ';
      } else if (postalCode >= 96950 && postalCode <= 96952) {
        state = 'Northern Marianas';
      } else if (
        (postalCode >= 601 && postalCode <= 799) ||
        (postalCode >= 900 &&
        postalCode <= 988)
      ) {
        state = 'Puerto Rico';
      } else if (postalCode >= 96910 && postalCode <= 96932) {
        state = 'Guam';
      } else if (postalCode >= 801 && postalCode <= 851) {
        state = 'US Virgin Islands';
      } else {
        state = null;
      }
    }
    return state;
  }
}
