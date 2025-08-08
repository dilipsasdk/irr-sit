@RestResource(urlMapping='/CaseFormV2/*')
global with sharing class CaseFormV2 {
  public class APIException extends Exception {
  }
  public class ValidationException extends Exception {
  }

  @HttpPost
  global static CaseFormResponse createCase(CaseFormJSONV2 form) {
    try {
      switch on form.formData.type {
        when 'claim' {
          CreateClaimRequest validatedRequest = null;
          try {
            validatedRequest = new CreateClaimRequest(form);
          } catch (CreateClaimRequest.CurrencyCountryMismatchException e) {
            throw e;
          } catch (Exception e) {
            throw new ValidationException(e.getMessage());
          }
          return new CaseFormResponse(
            ClaimService.createClaim(validatedRequest)
          );
        }
        when 'denied-boarding' {
          CreateClaimRequest validatedRequest = null;
          try {
            validatedRequest = new CreateClaimRequest(form);
          } catch (Exception e) {
            throw new ValidationException(e.getMessage());
          }
          return new CaseFormResponse(
            ClaimService.createCompensationCardClaim(validatedRequest)
          );
        }
        when 'delay-certificate' {
          return new CaseFormResponse(
            ClaimService.processFlightDelayCertificateRequest(form)
          );
        }
        when 'refund' {
          CreateRefundRequest validatedRequest = null;
          try {
            validatedRequest = new CreateRefundRequest(form);
          } catch (Exception e) {
            throw new ValidationException(e.getMessage());
          }

          return new CaseFormResponse(
            RefundService.createRefund(validatedRequest)
          );
        }
        when 'feedback' {
          CreateFeedbackRequest validatedRequest = null;
          try {
            validatedRequest = new CreateFeedbackRequest(form);
          } catch (Exception e) {
            throw new ValidationException(e.getMessage());
          }

          return new CaseFormResponse(
            FeedbackService.createCaseWithFeedback(validatedRequest)
          );
        }
        when 'medical' {
          CreateMedicalRequest validatedRequest = null;
          try {
            validatedRequest = new CreateMedicalRequest(form);
          } catch (Exception e) {
            throw new ValidationException(e.getMessage());
          }

          return new CaseFormResponse(
            MedicalService.sendMedicalEmail(validatedRequest)
          );
        }
        when 'group-travel' {
          CreateGroupTravelRequest validatedRequest = null;
          try {
            validatedRequest = new CreateGroupTravelRequest(form);
          } catch (Exception e) {
            throw new ValidationException(e.getMessage());
          }

          return new CaseFormResponse(
            GroupTravelServiceData.createGroupTravel(validatedRequest)
          );
        }
        when 'special-travel-needs' {
          CreateSpecialServiceRequest validatedRequest = null;
          try {
            validatedRequest = new CreateSpecialServiceRequest(form);
          } catch (Exception e) {
            throw new ValidationException(e.getMessage());
          }

          return new CaseFormResponse(
            SpecialServiceRequest.createSpecialService(validatedRequest)
          );
        }
        when else {
          return new CaseFormResponse('1');
          /*TODO: Implement
           return new CaseFormResponse(CaseService.createCase(form));*/
        }
      }
    } catch (CreateClaimRequest.CurrencyCountryMismatchException e) {
      logError(e);
      RestContext.response.statusCode = 400; // Bad Request
      RestContext.response.responseBody = Blob.valueOf(e.getMessage());
      return null;
    } catch (Exception e) {
      logError(e);
      throw new APIException();
    }
  }

  private static void logError(Exception e) {
    C_Log.log(
      C_Log.Severity.Error,
      e.getTypeName() + ': ' + e.getMessage(),
      e.getStackTraceString(),
      'CaseFormV2API',
      null
    );
  }
}
