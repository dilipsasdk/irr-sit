/**
* @author Chetan Singh, Coforge
* @date 2021
*
* @description Service class methods to be invoked by LWCScheduler.
*     
*/

public with sharing class IRR_LWCSchedulingService {
  /**
   * The setup utilities are used to manage scheduled jobs throughout the app. With these you can see the details
   * of a schedule job, schedule a job, or delete a scheduled job.
   */
  

   @AuraEnabled
   public static String getCurrentlyScheduledCron( String cronJobName){
    
    List<CronTrigger> cronTriggers = [
      SELECT id, CronExpression 
      FROM CronTrigger
      WHERE CronJobDetail.Name = :cronJobName
      LIMIT 1
      ];
      CronTrigger cronTrigger = (crontriggers.size() == 1) 
      ? crontriggers.get(0) 
      : null;

      if( cronTrigger != null) {
        return cronTrigger.CronExpression;
      }

      return null;

   }

   @AuraEnabled
   public static Boolean scheduleJob(String cronString, String cronJobName){
     try {
      SBS_ScheduledBatch scheduleAutomatedEvent = new IRR_BCH_SendAutomatedMessage (false);
       System.schedule(cronJobName, cronString, new IRR_BCH_SendAutomatedMessage (false));
       return true;
     } catch (Exception e) {
       System.debug(e.getMessage());
       return false;
     }
   }

   @AuraEnabled
   public static Boolean deleteScheduledJob(String cronJobName){
     try {
      List<CronTrigger> cronTriggers = [
        SELECT Id, CronExpression
        FROM cronTrigger
        WHERE CronJobDetail.Name = :cronJobName
        LIMIT 1
      ];
      CronTrigger cronTrigger = (crontriggers.size() == 1)? crontriggers.get(0):null;
      if( cronTrigger !=null){
        System.abortJob(cronTrigger.Id);
        
      }
      return true;
      
     } catch (Exception e) {
       System.debug(e.getMessage());
       return false;
     }
   }
}