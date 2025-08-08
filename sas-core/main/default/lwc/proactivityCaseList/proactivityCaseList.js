import { LightningElement, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getCasesForProactivity from "@salesforce/apex/ProactivitiesController.getCasesForProactivity";

export default class CaseProactivities extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  columns = [
    { label: "Case Number", fieldName: "CaseNumber" },
    { label: "Status", fieldName: "Status", initialWidth: 120 },
    {
      label: "Details",
      fieldName: "url",
      type: "url",
      typeAttributes: { label: "link" },
      initialWidth: 60
    }
  ];

  rows = [];
  showSpinner = true;
  error = undefined;
  casesFound = false;
  tooManyMatches = false;
  showTable = false;
  noMatchedCases = 0;
  MATCHLIMIT = 50; // More than this is not necessary, source: Nathan Allard + Alexander Vasberg

  get cardTitle() {
    if (this.tooManyMatches) {
      return "Matching Cases (50.000+)";
    } else if (this.noMatchedCases > this.MATCHLIMIT) {
      return `Matching Cases (${this.MATCHLIMIT} of ${this.noMatchedCases})`;
    } else {
      return `Matching Cases (${this.noMatchedCases})`;
    }
  }

  @wire(getCasesForProactivity, { proactivityId: "$recordId" })
  wiredCases({ error, data }) {
    if (error) {
      if (
        error.body.exceptionType == "ClaimsSelector.TooManyMatchesException"
      ) {
        this.rows = [];
        this.tooManyMatches = true;
        this.casesFound = true;
      } else {
        this.error = error;
      }
      this.showSpinner = false;
    } else if (data == undefined || data.length === 0) {
      this.rows = [];
      this.showSpinner = false;
      this.casesFound = false;
    } else {
      this.noMatchedCases = data.length;
      this.rows = data.slice(0, this.MATCHLIMIT).map((caseData, idx) => ({
        ...caseData,
        idx
      }));
      this.rows.forEach((row, idx) =>
        this[NavigationMixin.GenerateUrl]({
          type: "standard__recordPage",
          attributes: {
            recordId: row.Id,
            objectApiName: "Case",
            actionName: "view"
          }
        }).then((url) => {
          this.rows[idx] = { ...this.rows[idx], url };
          let res = [...this.rows];

          res[idx] = { ...res[idx], url };

          this.rows = res;
        })
      );

      this.showSpinner = false;
      this.casesFound = true;
      this.showTable = true;
    }
  }
}
