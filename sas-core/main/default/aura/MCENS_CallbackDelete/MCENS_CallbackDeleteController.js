({
    deleteRecord : function(cmp, evt, helper) {
        var action = cmp.get("c.deleteCallbackRecord");
        action.setParams({ "callbackRecordId" : cmp.get("v.recordId")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                let pageRef = {    
                    type: "standard__objectPage",
                    attributes: {
                        objectApiName : "MCENS_Callback__c",
                        actionName: "home"
                    }
                };
                cmp.find("navService").navigate(pageRef);
                $A.get("e.force:closeQuickAction").fire();
            }
            else if (state === "ERROR") {
                cmp.set("v.errorMessage",response.getError()[0].message);
            }
            else {
                cmp.set("v.errorMessage","Error when deleting the record")
            }
        });
        $A.enqueueAction(action);
    },
    cancelDialog : function(cmp, evt, helper){
        $A.get("e.force:closeQuickAction").fire();
    }
})
