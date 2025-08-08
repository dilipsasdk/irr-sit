import { LightningElement, api, track } from "lwc";
import createLog from "@salesforce/apex/C_Log.createLog";
export default class C_ErrorPanel extends LightningElement {
  /** Generic / user-friendly message */
  @api friendlyMessage =
    "An error occurred when trying to perform the operation. Please try again and contact an administrator if the error persists.";

  @track viewDetails = false;

  /** Single or array of LDS errors */
  @api errors;
  @track logs;
  @track error;
  @track errorType = "Error";
  @track logGroup = "LWC";
  @track errorMsg = undefined;
  @track stackTrace = undefined;
  get errorMessages() {
    if (!Array.isArray(this.errors)) {
      this.errors = [this.errors];
    }

    return (
      this.errors
        // Remove null/undefined items
        .filter((error) => !!error)
        // Extract an error message
        .map((error) => {
          // UI API read errors
          if (Array.isArray(error.body)) {
            console.log("inside a UI API Error");
            createLog({
              errorType: this.errorType,
              errorMsg: e.message,
              stackTrace: e.stack,
              logGroup: this.logGroup
            })
              .then((result) => {
                this.logs = result;
              })
              .catch((error) => {
                this.error = error;
              });
            return error.body.map((e) => e.message);
          }
          // UI API DML, Apex and network errors
          else if (error.body && typeof error.body.message === "string") {
            console.log("inside a Apex error");
            createLog({
              errorType: this.errorType,
              errorMsg: error.body.message,
              stackTrace: error.body.stackTrace,
              logGroup: this.logGroup
            })
              .then((result) => {
                this.logs = result;
              })
              .catch((error) => {
                this.error = error;
              });
            return error.body.message;
          }
          // JS errors
          else if (typeof error.message === "string") {
            console.log("inside a Js error");
            createLog({
              errorType: this.errorType,
              errorMsg: error.message,
              stackTrace: error.stack,
              logGroup: this.logGroup
            })
              .then((result) => {
                this.logs = result;
              })
              .catch((error) => {
                this.error = error;
              });

            return error.message;
          }
          // Unknown error shape so try HTTP status text
          return error.statusText;
        })
        // Flatten
        .reduce((prev, curr) => prev.concat(curr), [])
        // Remove empty strings
        .filter((message) => !!message)
    );
  }

  handleCheckboxChange(event) {
    this.viewDetails = event.target.checked;
  }
}
