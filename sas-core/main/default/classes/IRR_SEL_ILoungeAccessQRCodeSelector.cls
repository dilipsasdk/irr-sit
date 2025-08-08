/**
* @author Ragbirendra Upadhyay, CoforgeTech
* @date 2023
*
*/
public interface IRR_SEL_ILoungeAccessQRCodeSelector extends fflib_ISObjectSelector{
   
   List<AggregateResult> selectActiveRecordCount();
   List<IRR_LoungeAccessQRCode__c> getActiveQR(Integer size);
   List<IRR_LoungeAccessQRCode__c> getActiveQR();
}