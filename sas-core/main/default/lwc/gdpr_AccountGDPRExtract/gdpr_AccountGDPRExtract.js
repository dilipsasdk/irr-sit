/**
 * @author Anton Norell
 * @date 2019-12-18
 * @description JS constoller for component used to generate GDPR extract for a customer.
 */
import { LightningElement, track, api } from "lwc";
import generateExtractFile from "@salesforce/apex/GDPR_AccountGDPRExtractController.generateExtractFile";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class Gdpr_AccountGDPRExtract extends LightningElement {
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
   * Used to call controller to generate an extract for the customer in context. Opens a link to download the generated file.
   * @returns {Promise<void>}
   */
  async downloadExtract() {
    try {
      this.showSpinner = true;
      let contentVersion = await generateExtractFile({
        accountId: this.recordId
      });
      await window.open(
        "/sfc/servlet.shepherd/version/download/" + contentVersion.Id
      );
      this.showSpinner = false;
      const event = new ShowToastEvent({
        title: "GDPR Extract",
        message: "Extract generated successfully",
        variant: "success"
      });
      this.dispatchEvent(event);
    } catch (error) {
      this.showSpinner = false;
      this.displayError(error);
    }
  }
  displayError(error) {
    this.error = error;
  }
}
