public class PermissionSetSplitter {
    @InvocableMethod(label='Split Permission Set IDs' description='Splits a comma-separated list of Permission Set IDs from a single String into individual IDs')
    public static List<List<String>> splitPermissionSetIDs(List<String> coll_PermissionIds) {
        List<String> permissionSetIds = new List<String>();
        // Check if the field is not null, remove brackets, and split the string into individual IDs
        String permissionIdString = coll_permissionIds[0];
        if (String.isNotBlank(permissionIdString)) {
            // Remove the square brackets and any spaces that may cause issues when splitting
            String cleanedString = permissionIdString.replaceAll('\\[|\\]|\\s', '');
            permissionSetIds = cleanedString.split(',');
        }
        // Wrapping the list of strings in another list to conform to InvocableMethod requirements
        List<List<String>> result = new List<List<String>>();
        result.add(permissionSetIds);
        return result;
    }
}