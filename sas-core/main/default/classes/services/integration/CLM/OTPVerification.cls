public with sharing class OTPVerification {
  @AuraEnabled
  public String euroBonusNumber { get; private set; }
  @AuraEnabled
  public String status { get; private set; }
  @AuraEnabled
  public String recipient { get; private set; }
  @AuraEnabled
  public Integer remainingAttempts { get; private set; }

  private static final Integer MAX_ATTEMPTS = 6;

  @SuppressWarnings('PMD.ExcessiveParameterList')
  public OTPVerification(
    String euroBonusNumber,
    String status,
    String recipient,
    Integer remainingAttempts
  ) {
    this.euroBonusNumber = euroBonusNumber;
    this.status = status;
    this.recipient = recipient;
    this.remainingAttempts = remainingAttempts;
  }
  public OTPVerification(
    CLMValidationSuccess rawSuccessResponse,
    String euroBonusNumber
  ) {
    this(
      euroBonusNumber,
      rawSuccessResponse.status,
      rawSuccessResponse.otpReciever,
      MAX_ATTEMPTS
    );
  }
  public OTPVerification(
    CLMValidationFailure rawFailureResponse,
    String euroBonusNumber
  ) {
    this(
      euroBonusNumber,
      rawFailureResponse.status,
      rawFailureResponse.otpReciever,
      rawFailureResponse.otpRetryCount
    );
  }
}
