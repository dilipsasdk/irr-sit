import { LightningElement, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import searchCases from "@salesforce/apex/CareCasesController.searchCases";

export default class CareCaseSearch extends NavigationMixin(LightningElement) {
  @api recordId;
  columns = [
    {
      label: "Case",
      fieldName: "url",
      type: "url",
      typeAttributes: {
        label: {
          fieldName: "Case_Id__c"
        }
      }
    },
    {
      label: "PNR",
      fieldName: "Booking_Reference__c",
      cellAttributes: {
        class: {
          fieldName: "classNamePnr"
        }
      }
    },
    {
      label: "PIR",
      fieldName: "PIR__c",
      cellAttributes: {
        class: {
          fieldName: "classNamePir"
        }
      }
    }
  ];

  caseId = "";
  pnr = "";
  pir = "";

  rows = [];
  showSpinner = false;
  error = undefined;
  casesFound = false;
  searched = false;

  get casesFoundText() {
    return `${this.rows.length} case${this.rows.length === 1 ? "" : "s"} found`;
  }

  handleCaseIdChange(event) {
    this.caseId = event.target.value;
  }

  handlePNRChange(event) {
    this.pnr = event.target.value;
  }

  handlePIRChange(event) {
    this.pir = event.target.value;
  }

  async handleSearchButtonClick() {
    this.error = undefined;
    this.showSpinner = true;
    this.rows = [];
    try {
      const results = await searchCases({
        bookingReference: this.pnr,
        pir: this.pir,
        caseId: this.caseId
      });

      this.rows = results;
      this.rows.forEach((row, idx) =>
        this[NavigationMixin.GenerateUrl]({
          type: "standard__recordPage",
          attributes: {
            recordId: row.Id,
            objectApiName: "CARE_Claim__c",
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
      this.searched = true;
      if (results.length > 0) {
        this.casesFound = true;
      }
    } catch (error) {
      this.error = error;
      this.showSpinner = false;
    }
  }
}
