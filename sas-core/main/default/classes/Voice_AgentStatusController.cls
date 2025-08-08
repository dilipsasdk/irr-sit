// Unfortunalty this class cannot be unit tested.
// The problem is that you cannot create a UserServicePresence with a specific StatusStartDate (field is not writable)
public with sharing class Voice_AgentStatusController {

    // Return the presences grouped by label for the running user for today
    @AuraEnabled(cacheable=true)
    public static List<AgentPresenceWrapper> getAgentPresenceOverview() {
        integer totalLoggedInTime = 0;
        integer totalBreakTime = 0;
        
        // Get all preseneces for the running user for today
        List<UserServicePresence> results = [SELECT ServicePresenceStatus.MasterLabel, IdleDuration, 
                                              AtCapacityDuration, StatusDuration, StatusStartDate 
                                             FROM UserServicePresence 
                                             WHERE userid = :UserInfo.getUserId() 
                                              AND StatusStartDate = TODAY];
        
        // Map the SOQL result to the output map
        Map<String, AgentPresenceWrapper> agentPresences = new Map<String, AgentPresenceWrapper>();
        for (UserServicePresence agentPresence : results) {
            
            // Create wrapper object that will be displayed in the UI
            AgentPresenceWrapper wrapper = agentPresences.get(agentPresence.ServicePresenceStatus.MasterLabel);
            // If the presence is not in the map then create a wrapper
            if (wrapper == null) {
                wrapper = new AgentPresenceWrapper();
                wrapper.presence = agentPresence.ServicePresenceStatus.MasterLabel;
                wrapper.durationSeconds = getDurationSeconds(agentPresence);
                agentPresences.put(agentPresence.ServicePresenceStatus.MasterLabel, wrapper);
            }
            // presence is in the map then update the wrapper
            else {
                wrapper.durationSeconds += getDurationSeconds(agentPresence);

            }
            wrapper.durationFormatted = formatDuration(wrapper.durationSeconds);
            
            if (wrapper.presence == 'Lunch' || wrapper.presence == 'Break') {
                totalBreakTime += getDurationSeconds(agentPresence);
            }
            else {
                totalLoggedInTime += getDurationSeconds(agentPresence);
            }
        }
        // Add totals
        AgentPresenceWrapper wrapper = new AgentPresenceWrapper();
        wrapper.presence = 'Total logged in time';
        wrapper.durationSeconds = totalLoggedInTime;
        wrapper.durationFormatted = formatDuration(totalLoggedInTime);
        agentPresences.put(wrapper.presence, wrapper);        
        wrapper = new AgentPresenceWrapper();
        wrapper.presence = 'Total break time';
        wrapper.durationSeconds = totalBreakTime;
        wrapper.durationFormatted = formatDuration(totalBreakTime);
        agentPresences.put(wrapper.presence, wrapper); 
        
        return agentPresences.values();
    }
    
    // Return the offered voicecalls grouped by queuename for the running user for today
    @AuraEnabled(cacheable=true)
    public static List<CallWrapper> getAgentCallOverview() {
        integer totalOfferedCalls = 0;
        integer totalDroppedCalls = 0;
        
        // Get all voicecalls for the running user for today
        List<VoiceCall> results = [SELECT Call_Dropped__c, QueueName 
                                   FROM VoiceCall 
                                   WHERE ownerId = :UserInfo.getUserId() 
                                    AND CreatedDate = TODAY];
        
        // Map the SOQL result to the output map
        Map<String, CallWrapper> agentCalls = new Map<String, CallWrapper>();
        for (VoiceCall voiceCall : results) {
            // Create wrapper object that will be displayed in the UI
            CallWrapper wrapper = agentCalls.get(voiceCall.QueueName);
            // If the queuename is not in the map then create a wrapper
            if (wrapper == null) {
                wrapper = new CallWrapper();
                wrapper.QueueName = voiceCall.QueueName;
                wrapper.offeredCalls = 0;
                wrapper.droppedCalls = 0;
                agentCalls.put(wrapper.QueueName, wrapper);
            }
            wrapper.offeredCalls += 1;
            totalOfferedCalls += 1;
            if (voiceCall.Call_Dropped__c) {
                wrapper.droppedCalls += 1;
                totalDroppedCalls += 1;
            }
        }
        // Add a total row
        CallWrapper wrapper = new CallWrapper();
        wrapper.QueueName = 'Total';
        wrapper.offeredCalls = totalOfferedCalls;
        wrapper.droppedCalls = totalDroppedCalls;
        agentCalls.put(wrapper.QueueName, wrapper);
        
        return agentCalls.values();
    }
    
    @AuraEnabled(cacheable=true)
    public static CallWrapper getTotalCallOverview() {
        // Get all voicecalls for the running user for today
        List<PendingServiceRouting> results = [SELECT CreatedDate
                                               FROM PendingServiceRouting 
                                               WHERE CreatedDate = TODAY 
                                                AND QueueId in (SELECT queueid 
                                                                FROM QueueSobject 
                                                                WHERE sobjecttype = 'VoiceCall')];
        
        Integer callsWaiting = 0;
        Integer waitingTime = 0;
        for (PendingServiceRouting pendingServiceRouting : results) {
            callsWaiting += 1;
            waitingTime += (Integer)(DateTime.Now().getTime() - pendingServiceRouting.CreatedDate.getTime()) / 1000;
        }
        CallWrapper wrapper = new CallWrapper();
        wrapper.QueueName = 'Total';
        wrapper.callsWaiting = callsWaiting;
        wrapper.averageWaitingTime = (callsWaiting == 0) ? '0s' : String.valueOf(waitingTime / callsWaiting) + 's';
        return wrapper;
    }
    
    private static string formatDuration(Integer duration) {
        Integer hours = duration / 3600; 
        Integer minutes = (duration/60) - (hours *60);
        return hours + ':' + (minutes < 10 ? '0' : '') + minutes;          
    }
    
    // When a presence is completed, then return the presence duration.
    // When a presence is active, the return the seconds in the active presence
    private static Integer getDurationSeconds(UserServicePresence agentPresence) {
        Long seconds;
        if (agentPresence.StatusDuration == null){
            Long milliseconds = DateTime.Now().getTime() - agentPresence.StatusStartDate.getTime();
            seconds = milliseconds / 1000;
        }
        else {
            seconds = Math.round(agentPresence.StatusDuration);
        }
        
        return (Integer) seconds;
    }
    
    public class AgentPresenceWrapper {
        @AuraEnabled public String presence;
        @AuraEnabled public Integer durationSeconds;
        @AuraEnabled public String durationFormatted;
    }
    
    public class CallWrapper {
        @AuraEnabled public String queueName;
        @AuraEnabled public Integer offeredCalls;
        @AuraEnabled public Integer droppedCalls;
        @AuraEnabled public Integer callsWaiting;
        @AuraEnabled public String averageWaitingTime;
    }
}