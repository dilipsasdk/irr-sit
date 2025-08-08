@IsTest
public with sharing class CustomerVerificationController_Test {
  @IsTest
  public static void canRequestOtp() {
    Test.setMock(HttpCalloutMock.class, new CLMMock());
    Test.startTest();
    OTPVerification res = CustomerVerificationController.requestOtp(
      CLMMock.VALID_CLM_EBNUMBER
    );
    Test.stopTest();
    Assert.areEqual('SENT', res.status, 'Status should be SENT');
    Assert.areEqual(
      CLMMock.VALID_CLM_EBNUMBER,
      res.euroBonusNumber,
      'EBNumber should be the same'
    );
  }

  @IsTest
  public static void canHandleAbusedOtpRequest() {
    Test.setMock(HttpCalloutMock.class, new CLMMock());
    Test.startTest();
    OTPVerification res = CustomerVerificationController.requestOtp(
      CLMMock.ABUSED_CLM_EBNUMBER
    );
    Test.stopTest();
    Assert.areEqual('ABUSED', res.status, 'Status should be ABUSED');
    Assert.areEqual(
      CLMMock.ABUSED_CLM_EBNUMBER,
      res.euroBonusNumber,
      'EBNumber should be the same'
    );
  }

  @IsTest
  public static void canVerifyOtp() {
    Test.setMock(HttpCalloutMock.class, new CLMMock());
    Test.startTest();
    OTPVerification res = CustomerVerificationController.verifyOtp(
      CLMMock.VALID_CLM_EBNUMBER,
      CLMMock.VALID_CLM_OTP
    );
    Test.stopTest();
    Assert.areEqual('VERIFIED', res.status, 'Status should be VERIFIED');
  }

  @IsTest
  public static void incorrectOtpIsHandledGracefully() {
    Test.setMock(HttpCalloutMock.class, new CLMMock());
    Test.startTest();
    OTPVerification res = CustomerVerificationController.verifyOtp(
      CLMMock.VALID_CLM_EBNUMBER,
      CLMMock.INVALID_CLM_OTP
    );
    Test.stopTest();
    Assert.areEqual('RETRY', res.status, 'Status should be RETRY');
  }
}
