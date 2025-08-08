({
    saveRecord : function(cmp, evt, helper){
        evt.preventDefault();
        cmp.set("v.errorMessage","");
        cmp.find("cbName").reportValidity();
        cmp.find("cbUrl").reportValidity();
        cmp.find("cbBatchSize").reportValidity();
        let error = !(cmp.find("cbName").checkValidity() && cmp.find("cbUrl").checkValidity() && cmp.find("cbBatchSize").checkValidity());
        if(!error){
            let cbName = cmp.get("v.cbName");
            let cbUrl = cmp.get("v.cbUrl");
            let cbBatchSize = cmp.get("v.cbBatchSize");
            $A.util.isEmpty(cbName)
            var action = cmp.get("c.registerCallback");
            action.setParams({ 
                callbackName : cmp.get("v.cbName"),
                callbackUrl : cmp.get("v.cbUrl"),
                batchSize : cmp.get("v.cbBatchSize")
            });
            action.setCallback(this, function(response){
                cmp.set("v.isSaving",false);
                var state = response.getState();
                if(state === "SUCCESS"){
                    let rec = response.getReturnValue();

                    let pageRef = {    
                        type: "standard__recordPage",
                        attributes: {
                            recordId: rec.Id,
                            objectApiName : "MCENS_Callback__c",
                            actionName: "view"
                        }
                    };
                    cmp.find("navService").navigate(pageRef);
                }
                else if (state === "ERROR") {
                    cmp.set("v.errorMessage",response.getError()[0].message+" \n"+response.getError()[0].stackTrace);
                }
                else {
                    cmp.set("v.errorMessage","Error when saving the record")
                }
            });
            cmp.set("v.isSaving",true);
            $A.enqueueAction(action);
        }

    },
    cancelDialog : function(cmp, evt, helper){
        let pageRef = {    
            type: "standard__objectPage",
            attributes: {
                objectApiName : "MCENS_Callback__c",
                actionName: "home"
            }
        };
        cmp.find("navService").navigate(pageRef);
    }
})
