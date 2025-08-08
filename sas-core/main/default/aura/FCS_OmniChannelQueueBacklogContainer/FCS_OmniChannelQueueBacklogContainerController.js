({
  /**
   * Registers handler for event indicating that the utility bar item is clicked. The handler calls a method in the
   * child LWC to refresh data in the component.
   */
  registerUtilityClickHandler: function(component, event, helper){
    let utilityBarAPI = component.find("utilitybar");
    let utilityClickHandler = function(response){
      console.log('Received event: ' + JSON.stringify(response));
      if(response.panelVisible){
        component.find('childLwc').refreshQueueStatus();
      }
    };

    utilityBarAPI.onUtilityClick({
      eventHandler: utilityClickHandler
    }).then(function(result){
      console.log('Utility event registered successfully: ' + result);
    }).catch(function(error){
      console.log('Utility event could not register: ' + error);
      component.set("v.error", error);
    });
  },

  /**
   * Runs when Aura component is initialized
   */
  doInit: function(component) {
    component.set("v.error", undefined);
  }
});