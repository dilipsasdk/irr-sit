({
	showErrorToast : function(title, message) {
        var toast = $A.get("e.force:showToast");
        if(toast){
            toast.setParams({
                title : title,
                message : message,
                type : "error"
            });
            toast.fire();
        }
    },
    
    findAndRemoveTranscriptWaitingForTab : function(cmp,helper,val){
        let transcriptSet = cmp.get("v.transcriptWaitingForTab");
        let idx = -1;
        for(let i=0;i<transcriptSet.length;i++){
            if(helper.idEquals(transcriptSet[i],val)){
                idx = i;
                break;
            }
        }
        if(idx!=-1){
            transcriptSet.splice(idx,1);
            cmp.set("v.transcriptWaitingForTab",transcriptSet);
        }
        return idx!=-1;
    },
    
    idEquals : function(id1,id2){
        if(id1==id2)return true;
        if(id1==null || id2==null)return false;
        if(id1.length<15 || id2.length<15)return false;
        return id1.substring(0,15) == id2.substring(0,15);
    }
})