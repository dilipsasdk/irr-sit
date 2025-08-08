public without sharing class GetAccountIdByPhoneNumber {

    @InvocableMethod(label='getId' description='Get the account Id for a phone number' category='Account')
    public static List<String> getId(List<String> phoneNumbers) {
        
        List<String> toReturn = new List<String>();
        
        // Loop over all Phone numbers provided by the OMNI flow 
        for (String phoneNumber : phoneNumbers) {
            List<Account> existingAccounts = [SELECT Id FROM Account WHERE PersonMobilePhone = :phoneNumber];
                // If Account is found, return the Id
                if (existingAccounts.size() > 0) {
                    toReturn.add(existingAccounts[0].Id);
                }
        }
        return toReturn;
    }
}