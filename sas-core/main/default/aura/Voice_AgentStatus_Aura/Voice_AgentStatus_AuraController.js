({
    // refresh the component when the component is clicked in the utilityBar
    registerUtilityClickHandler: function(component, event, helper){

        let utilityBarAPI = component.find("utilitybar");
        // Define the method that is called when the utility bar item is clicked
        let utilityClickHandler = function(response){
            console.log('Received event: ' + JSON.stringify(response));
            if(response.panelVisible){
                component.find('childLwc').handleRefresh();
            }
        };
        
        // Assign the method to the "Agent Status" utility bar button
        utilityBarAPI.onUtilityClick({
            eventHandler: utilityClickHandler
        }).then(function(result){
            console.log('Utility event registered successfully: ' + result);
        }).catch(function(error){
            console.log('Utility event could not register: ' + error);
            component.set("v.error", error);
        });
    },
})