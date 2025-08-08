// A flow component for minimising utility bar component.
// From https://github.com/alexed1/LightningFlowComponents/blob/9a617b2bca19f858af24af0f1b6efde7d548429f/flow_action_components/Summer18/MinimizeUtilityItem/force-app/main/default/aura/MinimizeUtilityItem/MinimizeUtilityItemController.js

({
	invoke : function(component, event, helper) {        
        var utilityAPI = component.find("utilitybar");
        if (utilityAPI != undefined) {
            utilityAPI.getUtilityInfo().then(function(response) {
                if (response.utilityVisible) {
                    utilityAPI.minimizeUtility();
                }
            })
        } 
    }
})
