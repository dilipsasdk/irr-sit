import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class CommunicationLog extends NavigationMixin(
  LightningElement
) {
  ENTRIES_TO_DISPLAY = 2;

  // data
  logs = [];

  // UI state
  showAllLogs = false;

  get communicationlogs() {
    return this.openCases.concat(this.closedCases);
  }

  @api
  set communicationlogs(value) {
    if (value != undefined && value.length > 0) {
      this.logs = value.map((log) => ({
        ...log,
        flightNumber: log.flightId
          ? log.flightId.substring(0, Math.min(6, log.flightId.length))
          : ""
      }));

      if (this.logs.length <= this.ENTRIES_TO_DISPLAY) {
        this.showAllLogs = true;
      }
    } else {
      this.logs = [];
      this.showAllLogs = true;
    }
    return true;
  }

  get logsCount() {
    return `${
      this.showAllLogs
        ? this.logs.length
        : Math.min(this.ENTRIES_TO_DISPLAY, this.logs.length)
    } of ${this.logs.length}`;
  }

  get hasNoLogs() {
    return this.logs.length === 0;
  }

  get visibleLogs() {
    return this.showAllLogs
      ? this.logs
      : this.logs.slice(0, Math.min(this.ENTRIES_TO_DISPLAY, this.logs.length));
  }

  handleDisplayAllLogs() {
    this.showAllLogs = true;
  }

  navigateToLogPage(event) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: event.target.dataset.id,
        objectApiName: "IRR_CommunicationLog__c",
        actionName: "view"
      }
    });
  }
}
