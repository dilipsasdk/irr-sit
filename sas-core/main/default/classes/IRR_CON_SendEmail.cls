/**
* @author Chetan Singh, Coforge
* @date 2022
*
* @description Controller class for the manual comm to send Passenger list to Hotel Accomodation tool.
*/

public class IRR_CON_SendEmail {

    @AuraEnabled
    public static map<String,String> SendCsvEmail(String PaxData,String FileName,List<String> SendTo) {

        PaxData = PaxData.replaceAll('"','');
        PaxData = PaxData.replaceAll('"','');
        map<String, String> result = new map<String, String> ();

        try{
            Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
            Blob csvBlob = blob.valueOf('\uFEFF'+PaxData);
            String csvName = FileName+'.xls';
            csvAttachment.contenttype='application/vnd.ms-excel; charset=UTF-8';
            csvAttachment.setFileName(csvName);
            csvAttachment.setBody(csvBlob);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String[] toAddresses = SendTo;
            List<String> ccAddresses = new List<String>();
            ccAddresses = System.label.CC_Address_Hotel_Acc.split(',');
            String subject = 'Salesforce Passenger data to Lexit Hotel Accommodation Tool';
            email.setSubject(subject);
            email.setToAddresses(toAddresses);
            email.setCcAddresses(ccAddresses);
            email.setPlainTextBody('Salesforce Passenger data to Lexit Hotel Accommodation Tool');
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});
            Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            if (r[0].success) {
                System.debug('The email was sent successfully-->');
                result.put('SUCCESS', 'The email was sent successfully--->');
            } else {
                System.debug('The email failed to send--> ' + r[0].errors[0].message);
                result.put('ERROR', 'The email failed to send---> ' + r[0].errors[0].message);
            }
        }
        catch(Exception EX)
        {
            System.debug('The email failed to send----> ' + Ex.getMessage());
            result.put('ERROR', 'The email failed to send----> ' + Ex.getMessage());
        }
        return result;
    }
}
