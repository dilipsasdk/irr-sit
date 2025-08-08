import { LightningElement, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getProactivitiesForRecord from "@salesforce/apex/ProactivitiesController.getProactivitiesForRecord";

/**
 * A component which displays a list of proactivities for the given record.
 *
 * Currently can be added to Case and Settlement record pages. If these should
 * be visible elsewhere, ProactivitiesController needs to be extended to be
 * able to fetch proactivities for new object types. See implementation of
 * ProactivitiesController.getProactivitiesForRecord.
 */
export default class CaseProactivities extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @api objectApiName;

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
    },
    { label: "Match on", fieldName: "matchingReasons", initialWidth: 120 }
  ];

  rows = [];
  showSpinner = true;
  error = undefined;
  proactivitiesFound = false;

  sortProactivitiesByMatches(first, second) {
    // Sort first by proactivity type (Major event is always first), then string length as that is a good enough proxy for quality of match.
    if (first.typeIcon != second.typeIcon) {
      if (first.typeIcon === "standard:announcement") {
        return -1;
      } else if (second.typeIcon === "standard:announcement") {
        return 1;
      }
    }
    if (first.matchingReasons.length < second.matchingReasons.length) {
      return 1;
    } else if (first.matchingReasons.length > second.matchingReasons.length) {
      return -1;
    } else {
      // If the length is same, sort alphabetically.
      return [first.matchingReasons, second.matchingReasons].sort()[0] ===
        first.matchingReasons
        ? 1
        : -1;
    }
  }

  @wire(getProactivitiesForRecord, {
    recordId: "$recordId",
    objectApiName: "$objectApiName"
  })
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
          id: proactivity.id,
          note: proactivity.note,
          matchingReasons: proactivity.matchingReasons,
          typeIcon:
            proactivity.type == "Major Event"
              ? "standard:announcement"
              : proactivity.type == "Automatically Created"
              ? "standard:bot"
              : "standard:note"
        }))
        .sort(this.sortProactivitiesByMatches)
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
    }
  }
}
