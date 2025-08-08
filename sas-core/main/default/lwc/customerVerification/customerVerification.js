import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import requestOtp from "@salesforce/apex/CustomerVerificationController.requestOtp";
import verifyOtp from "@salesforce/apex/CustomerVerificationController.verifyOtp";

export default class CustomerVerification extends LightningElement {
  @api euroBonusNumber;
  @track showSpinner = false;

  status = "";
  otp;

  //max attempts is given by the CLM API
  //we initialize it 1 to allow the first attempt then override it with the actual value
  remainingVerificationAttempts = 1;
  requestAttempts = 4;

  statusToMessage = {
    NOTSENT: "Could not find a customer for the entered EuroBonus number",
    SENT: "One-Time Password was sent",
    RETRY: "The One-Time Password does not match the expected value",
    VERIFIED: "Successfully verified customer",
    ABUSED: "Could not verify customer",
    EXPIRED: "Verification code expired",
    PENDING: "Verification code pending",
    INIT: "Enter a EuroBonus number to start verification"
  };

  @track currentMessage = this.statusToMessage.INIT;

  get isVerified() {
    return this.status === "VERIFIED";
  }

  get isValidation() {
    return (
      (this.status === "SENT" || this.status === "RETRY") &&
      !this.noRemainingAttempts
    );
  }

  get noRemainingAttempts() {
    return this.remainingVerificationAttempts === 0;
  }

  get showReset() {
    return this.isVerified || this.noRemainingAttempts;
  }

  get action() {
    switch (this.status) {
      case "VERIFIED":
        return { icon: "utility:success", variant: "success" };
      case "SENT":
        return { icon: "utility:spinner", variant: "warning" };
      case "RETRY":
        return { icon: "utility:ban", variant: "error" };
      case "ABUSED":
        return { icon: "utility:error", variant: "error" };
      default:
        return { icon: "utility:prompt", variant: "default" };
    }
  }

  get disableRequest() {
    if (this.euroBonusNumber && this.euroBonusNumber.length === 9) {
      return false;
    } else {
      return true;
    }
  }

  get disableVerify() {
    if (this.otp && this.otp.length === 6) {
      return false;
    } else {
      return true;
    }
  }

  handleError() {
    const evt = new ShowToastEvent({
      title: "Unexpected Error",
      message:
        "An error occurred while processing your request. Please contact your Salesforce administrator.",
      variant: "error",
      mode: "dismissable"
    });
    this.dispatchEvent(evt);
  }

  handleReset() {
    this.status = "";
    this.otp = "";
    this.currentMessage = this.statusToMessage.INIT;
    this.remainingVerificationAttempts = 1;
  }

  handleEuroBonusNumber(event) {
    this.euroBonusNumber = event.target.value;
  }

  handleOtp(event) {
    this.otp = event.target.value;
  }

  createMessageFromResult(result) {
    let toReturn = "";
    switch (result.status) {
      case "NOTSENT":
      case "ABUSED":
      case "EXPIRED":
      case "PENDING":
      case "VERIFIED":
        toReturn = this.statusToMessage[result.status];
        break;
      case "RETRY":
        toReturn = `${
          this.statusToMessage[result.status]
        } Remaining attempts: ${this.remainingVerificationAttempts}`;
        break;
      case "SENT":
        toReturn = `${this.statusToMessage[result.status]} via ${
          result.recipient
        }`;
        break;
      default:
        console.log("Unknown status");
    }
    return toReturn;
  }

  async handleRequest() {
    this.showSpinner = true;
    if (this.requestAttempts > 0) {
      await requestOtp({ euroBonusNumber: this.euroBonusNumber })
        .then((result) => {
          this.requestAttempts--;
          this.status = result.status;
          this.remainingVerificationAttempts = result.remainingAttempts;
          this.currentMessage = this.createMessageFromResult(result);
        })
        .catch((error) => {
          this.handleError();
        });
    }
    this.showSpinner = false;
  }

  async handleVerify() {
    this.showSpinner = true;
    if (!this.noRemainingAttempts) {
      await verifyOtp({
        euroBonusNumber: this.euroBonusNumber,
        otp: this.otp
      })
        .then((result) => {
          this.remainingVerificationAttempts--;
          this.status = result.status;
          this.currentMessage = this.createMessageFromResult(result);
        })
        .catch((error) => {
          this.handleError();
        });
    }
    this.showSpinner = false;
  }
}
