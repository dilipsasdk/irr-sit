/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Test class for Static Input Apex Action.
*/

@IsTest
private class IRR_ACT_StaticInput_Test {

    @IsTest
    static void testStaticInput() {
        //Given
        IRR_MOD_FlowVariables flowVariables = new IRR_MOD_FlowVariables();
        flowVariables.delayInfo = new IRR_MOD_DelayInfo();
        flowVariables.passengerInfo = new IRR_MOD_PassengerInfo();
        IRR_ACT_StaticInput.actionOutput = flowVariables;

        //When
        List<IRR_MOD_FlowVariables> result = IRR_ACT_StaticInput.getActionOutput();

        //Then
        System.assertEquals(1, result.size());
        System.assertEquals(flowVariables, result[0]);
    }
}