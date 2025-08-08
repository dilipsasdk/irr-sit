/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Unit test class for the Manual Templates Selector.
*/

@IsTest
private class IRR_SEL_ManualTemplatesSelector_Test {

    @IsTest
    static void testSelectAllManualCommunicationTemplates() {
        List<IRR_ManualCommunicationTemplate__mdt> manualTemplates =
                IRR_SEL_ManualTemplatesSelector.newInstance().selectAllManualCommunicationTemplates();
        System.assertEquals([SELECT COUNT() FROM IRR_ManualCommunicationTemplate__mdt], manualTemplates.size());
    }
}