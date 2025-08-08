/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Unit test class for the Organization selector class.
*/

@IsTest
private class IRR_SEL_OrganizationSelector_Test {

    @IsTest
    static void testSelectOrganization() {
        Organization org = IRR_SEL_OrganizationSelector.newInstance().selectOrganization();
        System.assertNotEquals(null, org);
        System.assertNotEquals(null, org.Id);
        System.assertNotEquals(null, org.IsSandbox);
    }
}