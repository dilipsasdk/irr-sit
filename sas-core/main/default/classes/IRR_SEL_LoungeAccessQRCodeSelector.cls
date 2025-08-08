/**
* @author Ragbirendra Upadhyay, CoforgeTech
* @date 2023
*
*/
public class IRR_SEL_LoungeAccessQRCodeSelector extends fflib_SObjectSelector
implements IRR_SEL_ILoungeAccessQRCodeSelector {
    public static IRR_SEL_ILoungeAccessQRCodeSelector newInstance() {
        return (IRR_SEL_ILoungeAccessQRCodeSelector)
            IRR_Application.Selector.newInstance(IRR_LoungeAccessQRCode__c.SObjectType);
    }
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>
        {
            IRR_LoungeAccessQRCode__c.Id,
            IRR_LoungeAccessQRCode__c.expiryDate__c,
            IRR_LoungeAccessQRCode__c.voucher_Code__c,
            IRR_LoungeAccessQRCode__c.Status__c
        };
    } 
    public Schema.SObjectType getSObjectType() {
        return IRR_LoungeAccessQRCode__c.SObjectType;
    }
   
    public List<IRR_LoungeAccessQRCode__c> getActiveQR(Integer recordCount) {
        String status = 'Active';
        fflib_QueryFactory queryFactory = newQueryFactory()
            .setCondition('Status__c = :status')
            .setLimit(recordCount);
        List<IRR_LoungeAccessQRCode__c> loungeQRList = Database.query(queryFactory.toSOQL());
        return loungeQRList;   
    }
    public List<IRR_LoungeAccessQRCode__c> getActiveQR() {
        String status = 'Active';
        fflib_QueryFactory queryFactory = newQueryFactory()
            .setCondition('Status__c = :status');
        List<IRR_LoungeAccessQRCode__c> loungeQRList = Database.query(queryFactory.toSOQL());
        return loungeQRList;   
    }
    public List<AggregateResult> selectActiveRecordCount(){ 
     List<AggregateResult> result = [Select expiryDate__c, count(Id) totalCount From IRR_LoungeAccessQRCode__c where Status__c = 'Active'  Group by expiryDate__c ];
     
     system.debug('count:::'+result[0].get('totalCount'));
        return result;
    }
    
}