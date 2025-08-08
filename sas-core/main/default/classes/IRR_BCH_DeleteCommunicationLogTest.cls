/**
 * @author Gaurav Singh
 * @date 2024-06-12
 * @description Test class for IRR_BCH_DeleteCommunicationLog
 */
@IsTest
public  class IRR_BCH_DeleteCommunicationLogTest {
    @IsTest
    static void shouldOnlyDeleteExtractFiles(){
        IRR_CommunicationLog__c obj = new IRR_CommunicationLog__c();
        obj.IRR_BookingReference__c = '1b232';
        fflib_ISObjectUnitOfWork uow = IRR_Application.UnitOfWork.newInstance();
        uow.registerNew(obj);
        uow.commitWork();
        Test.setCreatedDate(obj.Id, Date.today().addDays(-91));
        Test.startTest();
        Database.executeBatch(new IRR_BCH_DeleteCommunicationLog());
        Test.stopTest();
    }
}