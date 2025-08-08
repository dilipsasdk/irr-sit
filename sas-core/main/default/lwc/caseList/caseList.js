import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class CaseList extends NavigationMixin(LightningElement) {
  ENTRIES_TO_DISPLAY = 2;

  // data
  closedCases = [];
  openCases = [];

  // UI state
  showAllClosedCases = false;
  showAllOpenCases = false;

  get cases() {
    return this.openCases.concat(this.closedCases);
  }

  @api
  set cases(value) {
    if (value != undefined && value.length > 0) {
      const sortedCases = [...value].sort((first, second) => {
        if (first.Status === "Closed" && second.Status !== "Closed") {
          return 1;
        } else if (first.Status !== "Closed" && second.Status === "Closed") {
          return -1;
        } else if (first.CreatedDate > second.CreatedDate) {
          return -1;
        } else if (first.CreatedDate < second.CreatedDate) {
          return 1;
        } else {
          return 0;
        }
      });

      this.closedCases = sortedCases
        .filter((c) => c.Status === "Closed" || c.Status === "Merged")
        .map((c) => ({
          ...c,
          className: "slds-item case-bullet closed-case-bullet",
          StatusOrReason: c.FCS_Case_Reason__c
        }));

      this.openCases = sortedCases
        .filter((c) => c.Status !== "Closed" && c.Status !== "Merged")
        .map((c) => ({
          ...c,
          className: "slds-item case-bullet open-case-bullet",
          StatusOrReason:
            c.FCS_Case_Reason__c != null
              ? c.Status + ", " + c.FCS_Case_Reason__c
              : c.Status
        }));

      if (this.closedCases.length <= this.ENTRIES_TO_DISPLAY) {
        this.showAllClosedCases = true;
      } else {
        this.showAllClosedCases = false;
      }
      if (this.openCases.length <= this.ENTRIES_TO_DISPLAY) {
        this.showAllOpenCases = true;
      } else {
        this.showAllOpenCases = false;
      }
    } else {
      this.closedCases = [];
      this.openCases = [];
      this.showAllClosedCases = true;
      this.showAllOpenCases = true;
    }
    return true;
  }

  get closedCasesCount() {
    return `${
      this.showAllClosedCases
        ? this.closedCases.length
        : Math.min(this.ENTRIES_TO_DISPLAY, this.closedCases.length)
    } of ${this.closedCases.length}`;
  }

  get openCasesCount() {
    return `${
      this.showAllOpenCases
        ? this.openCases.length
        : Math.min(this.ENTRIES_TO_DISPLAY, this.openCases.length)
    } of ${this.openCases.length}`;
  }

  get hasNoClosedCases() {
    return this.closedCases.length === 0;
  }

  get hasNoOpenCases() {
    return this.openCases.length === 0;
  }

  get hasNoOpenOrClosedCases() {
    return this.closedCases.length === 0 && this.openCases.length === 0;
  }

  get visibleClosedCases() {
    return this.showAllClosedCases
      ? this.closedCases
      : this.closedCases.slice(
          0,
          Math.min(this.ENTRIES_TO_DISPLAY, this.closedCases.length)
        );
  }

  get visibleOpenCases() {
    return this.showAllOpenCases
      ? this.openCases
      : this.openCases.slice(
          0,
          Math.min(this.ENTRIES_TO_DISPLAY, this.openCases.length)
        );
  }

  navigateToCaseViewPage(event) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: event.target.dataset.id,
        objectApiName: "Case",
        actionName: "view"
      }
    });
  }

  handleDisplayAllClosedCases() {
    this.showAllClosedCases = true;
  }
  handleDisplayAllOpenCases() {
    this.showAllOpenCases = true;
  }
}
