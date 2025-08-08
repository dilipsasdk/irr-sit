@RestResource(urlMapping='/RedeemCompensationCard/*')
global with sharing class RedeemCompensationCard {
  public class APIException extends Exception {
  }
  public class ValidationException extends Exception {
  }

  @HttpPost
  global static CaseFormResponse redeem(RedeemCompensationCardJSON data) {
    try {
      RedeemCompensationCardRequest validatedRequest = null;
      try {
        validatedRequest = new RedeemCompensationCardRequest(data);
      } catch (Exception e) {
        throw new ValidationException(e.getMessage());
      }
      return new CaseFormResponse(
        ClaimService.createCompensationCardClaim(validatedRequest)
      );
    } catch (Exception e) {
      C_Log.log(
        C_Log.Severity.Error,
        e.getTypeName() +
        ': ' +
        e.getMessage(),
        e.getStackTraceString(),
        'RedeemCompensationCardAPI',
        null
      );
      throw new APIException();
    }
  }
}
