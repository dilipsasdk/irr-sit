/**
* @author Niklas Lundkvist, Deloitte
* @date 2020
*
* @description Model class for IRR Messages.
*/

public class IRR_MOD_Message {

    public enum MessageChannel {SMS, Email}

    public MessageChannel channel;
    public String status;
    public String template;
    public Map<String, Object> variables;
    public String recipient;
    public String content;
    public IRR_MOD_PassengerInfo passengerInfo;
    public String contactKey;
    public IRR_SVC_SFMCService.SFMCMessage SFMCMessage;
    public String subject;
    public String type;
    public Boolean responseMessage;

    public String messageKey {
        get {
            return SFMCMessage != null ? SFMCMessage.messageKey : '';
        }
    }

    public IRR_MOD_Message() {
        //CONSTRUCTOR INTENTIONALLY LEFT EMPTY
    }

    public IRR_MOD_Message(String status, MessageChannel channel, Map<String, Object> variables, String template,
            IRR_MOD_PassengerInfo passengerInfo, String type, Boolean responseMessage) {
        this.responseMessage = responseMessage;
        this.type = type;
        this.status = status;
        this.channel = channel;
        this.template = template;
        this.variables = variables;
        if (channel == MessageChannel.SMS) {
            this.recipient = passengerInfo.phoneNumber;
            if (String.isNotBlank(this.recipient)) {
                if (this.recipient.startsWith('00')) this.recipient = this.recipient.substring(2);
                if (this.recipient.startsWith('+')) this.recipient = this.recipient.substring(1);
                
                if(this.recipient.startsWith('+') && this.recipient.contains('+46')){
                    string numberWithoutCountryCode = drop_leading_zeros(this.recipient.substring(2,this.recipient.length()));
                    this.recipient = '46' + numberWithoutCountryCode;
                }
                else  if( this.recipient.startsWith('46')){
                    string numberWithoutCountryCode = drop_leading_zeros(this.recipient.substring(2,this.recipient.length()));
                    this.recipient = '46' + numberWithoutCountryCode;
                }
            }
        }
        else {
            this.recipient = passengerInfo.emailAddress;
        }
        this.contactKey = String.isNotBlank(passengerInfo.emailAddress) ? passengerInfo.emailAddress :
                this.recipient;
        this.passengerInfo = passengerInfo;
    }



    public static String drop_leading_zeros(String passedValue) {
        String return_string = null; //return string for passing back
        if (passedValue != null) { //if the passed value is not null
            return_string = passedValue.trim(); //trim the whitespace from the start and end of the value
            Pattern valid_characters = Pattern.compile('([0-9]+)'); //only numbers
            Matcher check_chars = valid_characters.matcher(return_string); //compare the string to the set of valid characters
            if (check_chars.matches()) { //if we have a somewhat valid number
                if (return_string.startsWith('0') && return_string.length() > 1) { //if the string begins with a 0 and the length is greater than 1
                    boolean keepChecking = true; //create a boolean variable
                    while (keepChecking) { //if boolean is true
                        if (return_string.startsWith('0') && return_string.length() > 1) { //if the string begins with 0 and there is more than 1 character
                            return_string = return_string.substring(1); //drop the first character
                        } else { //either the string doesn't begin with 0 or the length is less than or equal to 1
                            keepChecking = false; //stop the loop
                        }
                    }
                }
                if (return_string == '0') { //if the resulting string is now a single '0'
                    return_string = null; //set the string to null
                }
            } else { //otherwise the value passed was not valid
                return_string = null; //set the string to null
            }
        }
        return return_string; //pass back a value
    }
}