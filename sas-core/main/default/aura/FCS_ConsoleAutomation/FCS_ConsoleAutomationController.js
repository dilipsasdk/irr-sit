({
    onInit : function(cmp, evt, helper) {
        let action = cmp.get("c.retrievePrefixes"); 
                action.setCallback(this, function(response){
                    let state = response.getState();
                    if(state=="SUCCESS"){
                        console.log('retrievePrefixes: ' + state);
                        let result = response.getReturnValue();
                        if(result!=null){
                            console.log(result);
                            cmp.set("v.prefixList",result);
                        }
                    }
                    else {
                        helper.showErrorToast("Component Error","Failed to retrieve the related prefixes for objects with subtabs, Server.");
                    }
                });
                $A.enqueueAction(action);
    },
    
    
    onWorkAccepted : function(cmp, evt, helper) {
        var prefixList = cmp.get("v.prefixList");
        var workItemId = evt.getParam('workItemId');
        var workItemIdPrefix = workItemId.substring(0,3);
        
        if(prefixList.includes(workItemIdPrefix)){
            let transcriptSet = cmp.get("v.transcriptWaitingForTab");
            transcriptSet.push(workItemId);
            cmp.set("v.transcriptWaitingForTab",transcriptSet);
        }
    }, 
    
    onTabCreated : function(cmp, evt, helper){
        let rootTabId = evt.getParam("tabId");
        let workspaceAPI = cmp.find("workspace");
		workspaceAPI.getTabInfo({tabId: rootTabId}).then(function(tabInfo){
            if(helper.findAndRemoveTranscriptWaitingForTab(cmp,helper,tabInfo.recordId)){
                let action = cmp.get("c.retrieveRelated"); 
                action.setParams({objId : tabInfo.recordId});
                action.setCallback(this, function(response){
                    let state = response.getState();
                    if(state=="SUCCESS"){
                        let result = response.getReturnValue();
                        if(result!=null){
                            for(var i=0; i<result.length; i++){
                                workspaceAPI.openSubtab({parentTabId: rootTabId,recordId:result[i],focus:false});
                            }
                        }
                    }
                    else {
                        helper.showErrorToast("Chat Error","Failed to retrieve the related case from the transcript, Server.");
                    }
                });
                $A.enqueueAction(action);
            }
        }).catch(function(error){
            helper.showErrorToast("Chat Error","Failed to get info of recently opened tab : "+error);
        });
    }
})