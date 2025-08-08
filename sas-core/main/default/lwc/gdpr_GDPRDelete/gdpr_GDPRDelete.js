/**
 * @author Anton Norell
 * @date 2019-12-18
 * @description JS controller for component used to delete data for customer
 */
import { LightningElement, track, api } from "lwc";
import wipeRecord from "@salesforce/apex/GDPR_DeleteComponentController.deleteRecordData";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class AccountGdprExtract extends LightningElement {
  /**
   * Id for Account record in context
   */
  @api recordId;

  /**
   * Variable to hold error. If assigned, the error is displayed in component.
   */
  @track error;

  /**
   * If true, a spinner is shown in component to indicate loading.
   */
  @track showSpinner;

  /**
   * If true, the delete button and input field on the component is disabled.
   */
  @track buttonDisabled;

  /**
   * Used to call controller to generate an extract for the customer in context. Opens a link to download the generated
   * file, and then deletes the file from Salesforce.
   * @returns {Promise<void>}
   */
  async deleteRecordData() {
    try {
      this.showSpinner = true;
      if (!this.validateInput()) {
        await wipeRecord({ recordId: this.recordId });
        const event = new ShowToastEvent({
          title: "GDPR Delete",
          message: "Successfully deleted data",
          variant: "success"
        });
        this.dispatchEvent(event);
        this.deleteDisabled = true;
      }
      this.showSpinner = false;
    } catch (error) {
      this.showSpinner = false;
      this.displayError(error);
    }
  }

  /**
   * Validates the value in the search field on component
   * Currently only checks if field is empty but should preferably be extended with further validations
   */
  validateInput() {
    let fieldError = true;
    let inputCmp = this.template.querySelector(".input-field");
    let value = inputCmp.value;
    if (value === "") {
      inputCmp.setCustomValidity("Please insert the record Id");
      fieldError = true;
    } else if (value === this.recordId) {
      inputCmp.setCustomValidity("");
      fieldError = false;
    } else {
      inputCmp.setCustomValidity("Incorrect record Id");
      fieldError = true;
    }
    inputCmp.reportValidity();
    return fieldError;
  }
  displayError(error) {
    this.error = error;
  }
}
