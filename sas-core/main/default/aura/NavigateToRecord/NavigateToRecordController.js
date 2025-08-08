({
  invoke: function (component, event, helper) {
    const navService = component.find("navService");
    const destinationRecordId = component.get("v.destinationRecordId");
    const destinationName = component.get("v.destinationName");

    const pageReference = {
      type: "standard__recordPage",
      attributes: {
        objectApiName: destinationName,
        recordId: destinationRecordId,
        actionName: "view"
      }
    };
    navService.navigate(pageReference);
  }
});
