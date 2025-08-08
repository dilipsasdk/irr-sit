({
  invoke : function(component, event, helper) {        
    return new Promise(function(resolve, reject) {
      component.find("recordLoader").reloadRecord(true, $A.getCallback(function() {
        resolve();
      }));
    });
  }
})