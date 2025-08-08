public without sharing class SasAccount {

    // Get the EB level for an EB number by searching for the account with that EB number.
    // If the account does not exist, COSD is searched for the EB number. 
    // If the account is found in CODS, it's added to Salesforce.
    @InvocableMethod(label='getId' description='Get the account Id a EB number' category='Account')
    public static List<Account> getId(List<String> eurobonusNumbers) {
        
        List<Account> toReturn = new List<Account>();
        
        // Loop over all EB numbers provided by the OMNI flow 
        for (String ebNumber : eurobonusNumbers) {
            // If the EB Number is provided (it could be that the customer does not type in an EB Number)
            if (String.isNotBlank(ebNumber)){
                // Search for the EB Number in SF
                List<Account> existingAccounts = AccountsSelector.newInstance().selectByEuroBonusNumber(new Set<String>{ebNumber});
                // If EB number found in Salesforce Then return the Account
                if (existingAccounts.size() > 0) {
                    toReturn.add(existingAccounts[0]);
                }
            }
        }
        return toReturn;
    }
}