/**
 * Get Us States from Postal code
 */
public without sharing class GetUsState {
  @InvocableMethod(label='Get US State')
  public static List<String> getState(List<String> zipCode) {
    List<String> zipCodes = new List<String>(new Set<String>(zipCode));
    String state;
    List<String> stateList = new List<String>{};
    for (String zipCd : ZipCodes) {
      state = UsStateUtils.getStateFromPostalCode(zipCd);
      stateList.add(state);
    }
    return stateList;
  }
}
