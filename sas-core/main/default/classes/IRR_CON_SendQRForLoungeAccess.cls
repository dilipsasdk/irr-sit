/**
* @author Ragbirendra Upadhyay, CoforgeTech
* @date 2023
*
* @description Controller class for the Send QR code for lounge access LWC page.
*/
public class IRR_CON_SendQRForLoungeAccess {

    
    
    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getActiveQRCount() {
        return IRR_SEL_LoungeAccessQRCodeSelector.newInstance().selectActiveRecordCount();
    }
   
    @AuraEnabled
    public static String sendEmailToCustomer(List<IRR_MOD_LoungeAccessInfo>  emailList) {
        List<String> emailAddressList = new List<String>();
        Integer totalQRString = emailList.size();
        Set<string> templateName = new Set<string>{'irr_lounge_access_QR_email'};
        List<IRR_LoungeAccessQRCode__c> totalVoucherCode = IRR_SEL_LoungeAccessQRCodeSelector.newInstance().getActiveQR(emailList.size());
        Map<String, EmailTemplate> emailTemplateMap = IRR_SEL_EmailTemplatesSelector.newInstance().selectEmailTemplatesByName(templateName);
       
        for(integer i=0;i<totalQRString ;i++){
            String voucherString = EncodingUtil.urlEncode(totalVoucherCode[i].voucher_Code__c, 'UTF-8');
            emailList[i].deactivateId = totalVoucherCode[i].Id;
            emailList[i].agentName = UserInfo.getName();
            emailList[i].subject = (emailTemplateMap.get('irr_lounge_access_qr_email')).Subject;
            String htmlBody = (emailTemplateMap.get('irr_lounge_access_qr_email')).HtmlValue;
            htmlBody = htmlBody.replace('{{{voucherString}}}', voucherString);
            htmlBody = htmlBody.replace('{{{expiryDate}}}', totalVoucherCode[i].expiryDate__c);
            htmlBody = htmlBody.replace('{{{serialNumber}}}', (totalVoucherCode[i].voucher_Code__c).substring(6,12));
            htmlBody = htmlBody.replace('{{{year}}}', String.valueOf(System.Today().year()));
            htmlBody = htmlBody.replace('{{{emailAddress}}}', emailList[i].emailAddress);
            emailList[i].htmlContent = htmlBody;
        }
        //Email send
        sendEmailTemplateToSFMC(emailList);
        updateLoungeAccessQRCodeRecord(emailList);
        return 'success';
    }
    public static void sendEmailTemplateToSFMC(List<IRR_MOD_LoungeAccessInfo> emailList){
        List<IRR_MOD_Message> messages = new List<IRR_MOD_Message>();
          List<IRR_SVC_SFMCService.EmailMessage> sfmcEmailMessages = new List<IRR_SVC_SFMCService.EmailMessage>();
          fflib_ISObjectUnitOfWork uow = IRR_Application.UnitOfWork.newInstance();
          for(IRR_MOD_LoungeAccessInfo loungeAccessInfo : emailList){
              IRR_SVC_SFMCService.EmailMessage message = new IRR_SVC_SFMCService.EmailMessage(
                loungeAccessInfo.htmlContent,loungeAccessInfo.subject ,loungeAccessInfo.emailAddress , loungeAccessInfo.emailAddress);
                if(isEmailWhitelisted(loungeAccessInfo.emailAddress)){
                    sfmcEmailMessages.add(message);
                    }
          }
          
          IRR_SVC_SFMCService.sendEmailMessages(sfmcEmailMessages);

          for(IRR_MOD_Message message : messages){
            System.debug('Printing message here.....'+ message);
          }
                      
    } 

	public static Boolean isEmailWhitelisted(String emailAddress){
        Organization org = IRR_SEL_OrganizationSelector.newInstance().selectOrganization();
        Set<String> whitelistedRecipients = IRR_SEL_RecipientWhitelistSelector.newInstance()
        .getAllWhitelistedRecipients();
        if (!org.IsSandbox || whitelistedRecipients.contains(emailAddress)) {
            return true;
        }
        else{
            return false;
        }
    }


    public static void updateLoungeAccessQRCodeRecord(List<IRR_MOD_LoungeAccessInfo> emailList){
        fflib_SObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(
            new List<Schema.SObjectType>{
                IRR_LoungeAccessQRCode__c.SObjectType
            }
        );
        List<SObject> updateList = new List<IRR_LoungeAccessQRCode__c>();
            for(IRR_MOD_LoungeAccessInfo loungeAccess:emailList){
               IRR_LoungeAccessQRCode__c updateLoungeAccess = new IRR_LoungeAccessQRCode__c();
               updateLoungeAccess.Id                      = loungeAccess.deactivateId ;
               updateLoungeAccess.Status__c               ='Sent';
               updateLoungeAccess.voucherCaseNumber__c    = loungeAccess.caseId !=''?loungeAccess.caseId:null;
               updateLoungeAccess.voucherSubmitter__c     = loungeAccess.agentName;
               updateLoungeAccess.Comment__c              = loungeAccess.comment;
               updateLoungeAccess.ReceiverEmailAddress__c = loungeAccess.emailAddress;
               updateList.add(updateLoungeAccess);
            }
            unitOfWork.registerUpsert(updateList);
            unitOfWork.commitWork();
    }
    @AuraEnabled
    public static string insertLoungeAccessQRString(String base64Data) {

       
        fflib_SObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(
            new List<Schema.SObjectType>{
                IRR_LoungeAccessQRCode__c.SObjectType
            }
        );  

        // Update all existing record to Invalid
        List<IRR_LoungeAccessQRCode__c> qrRecordList = IRR_SEL_LoungeAccessQRCodeSelector.newInstance().getActiveQR();
        for(IRR_LoungeAccessQRCode__c qrRecord:qrRecordList ){
            qrRecord.Status__c = 'Invalid';
        }
        unitOfWork.registerUpsert(qrRecordList);
        unitOfWork.commitWork();
              
        String data    = JSON.deserializeUntyped(base64Data).toString();
        list<SObject> lstLoungeAccessToInsert = new list<IRR_LoungeAccessQRCode__c>();
        list<String> lstCSVLines = data.split('\n');
        for(Integer i = 1; i < lstCSVLines.size(); i++){
            IRR_LoungeAccessQRCode__c loungeAccessQRCode = new IRR_LoungeAccessQRCode__c();
            String csvLine = lstCSVLines[i];
            String prevLine = csvLine;
            Integer startIndex;
            Integer endIndex;
            
            while(csvLine.indexOf('"') > -1){                
                if(startIndex == null){
                    startIndex = csvLine.indexOf('"');
                    csvLine = csvLine.substring(0, startIndex) + ':quotes:' + csvLine.substring(startIndex+1, csvLine.length());
                }else{
                    if(endIndex == null){
                        endIndex = csvLine.indexOf('"');
                        csvLine = csvLine.substring(0, endIndex) + ':quotes:' + csvLine.substring(endIndex+1, csvLine.length());
                    }
                }
                
                if(startIndex != null && endIndex != null){
                    String sub = csvLine.substring(startIndex, endIndex);
                    sub = sub.replaceAll(',', ':comma:');
                    csvLine = csvLine.substring(0, startIndex) + sub + csvLine.substring(endIndex, csvLine.length());
                    startIndex = null;
                    endIndex = null;
                }
            }
            
            List<String> csvRowData = new List<String>(); 
            for(String column : csvLine.split(',')){
                column = column.replaceAll(':quotes:', '').replaceAll(':comma:', ',');
                csvRowData.add(column);
            }
            LoungeAccessQRCode.voucher_Code__c  = csvRowData[0];
            LoungeAccessQRCode.expiryDate__c    = csvRowData[1];
            LoungeAccessQRCode.Status__c        = 'Active';
            
            lstLoungeAccessToInsert.add(LoungeAccessQRCode);
        }
                
        unitOfWork.registerNew(lstLoungeAccessToInsert);
        unitOfWork.commitWork();
        return 'Success';
    
    }
    
}