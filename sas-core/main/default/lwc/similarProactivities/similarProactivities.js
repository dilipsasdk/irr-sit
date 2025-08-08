import { LightningElement, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getDuplicateProactivities from "@salesforce/apex/ProactivitiesController.getDuplicateProactivities";

export default class SimilarProactivities extends NavigationMixin(
  LightningElement
) {
  @api recordId;

  columns = [
    {
      label: "Note",
      fieldName: "url",
      type: "url",
      typeAttributes: {
        label: {
          fieldName: "note"
        }
      },
      cellAttributes: {
        iconName: {
          fieldName: "typeIcon"
        }
      }
    }
  ];

  rows = [];
  showSpinner = true;
  error = undefined;
  proactivitiesFound = false;
  showTable = false;

  @wire(getDuplicateProactivities, { recordId: "$recordId" })
  wiredProactivities({ error, data }) {
    if (error) {
      this.showSpinner = false;
      this.error = error;
      this.proactivitiesFound = false;
    } else if (data == undefined || data.length === 0) {
      this.rows = [];
      this.showSpinner = false;
      this.proactivitiesFound = false;
    } else {
      this.rows = data
        .map((proactivity) => ({
          id: proactivity.Id,
          note: proactivity.Note__c,
          typeIcon:
            proactivity.Type__c == "Major Event"
              ? "standard:announcement"
              : proactivity.Type__c == "Automatically Created"
              ? "standard:bot"
              : "standard:note"
        }))
        .map((proactivity, idx) => ({ ...proactivity, idx }));

      this.rows.forEach((row, idx) =>
        this[NavigationMixin.GenerateUrl]({
          type: "standard__recordPage",
          attributes: {
            recordId: row.id,
            objectApiName: "Proactivity__c",
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
      this.proactivitiesFound = true;
      this.showTable = true;
    }
  }
}
