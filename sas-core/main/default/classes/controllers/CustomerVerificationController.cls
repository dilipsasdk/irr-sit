public with sharing class CustomerVerificationController {
  private static final CLMIntegrationService CLM_SERVICE = CLMIntegrationService.newInstance();

  @AuraEnabled
  public static OTPVerification requestOtp(String euroBonusNumber) {
    OTPVerification response = CLM_SERVICE.verifyCustomer(
      euroBonusNumber,
      null,
      UserInfo.getUserEmail(),
      CLMIntegrationService.OTPOperation.REQUEST
    );
    return response;
  }

  @AuraEnabled
  public static OTPVerification verifyOtp(String euroBonusNumber, Integer otp) {
    OTPVerification response = CLM_SERVICE.verifyCustomer(
      euroBonusNumber,
      otp,
      UserInfo.getUserEmail(),
      CLMIntegrationService.OTPOperation.VERIFY
    );
    return response;
  }
}
