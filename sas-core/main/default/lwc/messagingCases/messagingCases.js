import { LightningElement, api, wire, track } from "lwc";
import findCases from "@salesforce/apex/MessagingSessionController.findCases";
export default class MessagingCases extends LightningElement {
  @api recordId;
  @track cases = [];
  @track cse;
  @track error = undefined;
  @wire(findCases, {
    recordId: "$recordId"
  })
  wiredcse({ error, data }) {
    if (data) {
      this.cases = data;
    } else if (error) {
      this.displayError(error);
    }
  }
  displayError(error) {
    this.error = error;
  }
}
