/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Container class for Static Input Apex Action.
*/

public class IRR_ACT_StaticInput {

    public static IRR_MOD_FlowVariables actionOutput;

    /**
     * @author Niklas Lundkvist, Deloitte
     * @date 2020
     *
     * @description Workaround to provide Apex Defined object inputs for a Flow.
     *          *Warning* This action requires Apex setup and is not bulkified.
     *
     * @return Action Output variable
     */
    @InvocableMethod
    public static List<IRR_MOD_FlowVariables> getActionOutput() {
        return new List<IRR_MOD_FlowVariables>{actionOutput};
    }
}