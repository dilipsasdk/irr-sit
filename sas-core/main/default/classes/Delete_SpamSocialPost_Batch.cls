/*
Batch calss to delete spammed Social Post.
22-Nov-2021
*/

global class Delete_SpamSocialPost_Batch extends SBS_ScheduledBatch
{ /**
  List to Store Spam hash tags
*/
    List<String> lstSpamTags = new List<String>();
    /**
    The ScheduleBatchRunComponent record id for this particualr batch
    used to update the record with totalNumberOfRecords Deleted
    */
    String scheduledBatchRunComponentId;
    /**
    Used to count the totalnumber of records deleted.
    */
    Integer totalNumberOfRecordsDeleted = 0;
    
    global override void setVariables(
        String sObj,
        Integer retentionPeriod,
        string caseField,
        String caseType,
        String batchName,
        String scheduledBatchRunComponentId
    ) {
     this.scheduledBatchRunComponentId = scheduledBatchRunComponentId;
    }
    
    global Delete_SpamSocialPost_Batch()
    {
       List<Social_Post_Spam_Hash_Tags__c> spamSocialPostTags = Social_Post_Spam_Hash_Tags__c.getall().values();
        for(Social_Post_Spam_Hash_Tags__c sp:spamSocialPostTags )
        {
            lstSpamTags.add(sp.Spam_Hash_Tag__c);
        }
    }
    /**
Iterates over all interactions to be processed
@param bc The batch context
*/
    global Database.QueryLocator start(Database.BatchableContext bc) {
        string status = 'Needed';
        
        return Database.getQueryLocator('SELECT Content,Id,ReviewedStatus FROM SocialPost WHERE ReviewedStatus =:status');  
    }
    
    /**
Deletes the interactions which should be deleted according to the retention logic
@param bc The batchable context of the batch job
@param sObjScope The interactions to delete
*/
    global override void executeScope(
        Database.BatchableContext bc,
        SObject[] sObjScope
    ) {
        List<SocialPost> lstDelSocialPosts = new List<SocialPost>();
        for(SocialPost sc : (SocialPost[])sObjScope)
        {
            for(String spamTag : lstSpamTags)
            {
                if(sc.Content.contains(spamTag))
                {
                    lstDelSocialPosts.add(sc);
                    break;
                } 
            }
        }
        totalNumberOfRecordsDeleted = totalNumberOfRecordsDeleted + lstDelSocialPosts.size();
        delete lstDelSocialPosts;
        
    }
    global override void finishOverridable(
    Database.BatchableContext bc
  )
  {
    if(scheduledBatchRunComponentId!=null)
    {
    SBS_ScheduledBatchRunComponent__c sbrc = new SBS_ScheduledBatchRunComponent__c(
              Id = scheduledBatchRunComponentId,
              Total_Number_Of_Records_Processed__c = String.valueOf(totalNumberOfRecordsDeleted)
            );
            update sbrc;
      }      
  }
  
  
}