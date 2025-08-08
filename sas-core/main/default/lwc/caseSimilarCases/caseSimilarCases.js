import { LightningElement, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getSimilarCasesForCase from "@salesforce/apex/SimilarCasesController.getSimilarCasesForCase";

export default class CaseSimilarCases extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  columns = [
    {
      label: "Case",
      fieldName: "url",
      type: "url",
      typeAttributes: {
        label: {
          fieldName: "caseNumber"
        }
      }
    },
    { label: "Status", fieldName: "status" },
    { label: "Owner", fieldName: "owner" },
    { label: "Created", fieldName: "date", type: "date" },
    {
      label: "Customer Claim Type",
      fieldName: "customerClaimType",
      cellAttributes: {
        class: {
          fieldName: "classNameCustomerClaimType"
        }
      }
    },
    {
      label: "PNR",
      fieldName: "bookingReference",
      cellAttributes: {
        class: {
          fieldName: "classNamePnr"
        }
      }
    },
    {
      label: "PIR",
      fieldName: "pir",
      cellAttributes: {
        class: {
          fieldName: "classNamePir"
        }
      }
    },
    {
      label: "EB",
      fieldName: "EbNumber",
      cellAttributes: {
        class: {
          fieldName: "classNameEbNumber"
        }
      }
    },
    {
      label: "Flight Number",
      fieldName: "flightNumber",
      cellAttributes: {
        class: {
          fieldName: "classFlightNumber"
        }
      }
    },
    {
      label: "Flight Date",
      fieldName: "flightDate",
      cellAttributes: {
        class: {
          fieldName: "classFlightDate"
        }
      }
    },
    {
      label: "Email",
      fieldName: "email",
      cellAttributes: {
        class: {
          fieldName: "classNameEmail"
        }
      }
    },
    {
      label: "Department",
      fieldName: "department",
      cellAttributes: {
        class: {
          fieldName: "classNameDepartment"
        }
      }
    }
  ];

  rows = [];
  showSpinner = true;
  error = undefined;
  similarCasesFound = false;

  get cardTitle() {
    return `Similar Cases (${this.rows.length})`;
  }

  // Sorts cases first on number of matches and secondarily on matching field names for a grouped sort.
  sortCasesBySimilarity(first, second) {
    const subSort = (a, b) => {
      if (
        a.matchingFields == undefined ||
        a.matchingFields[0] == undefined ||
        b.matchingFields == undefined ||
        b.matchingFields[0] == undefined
      ) {
        return 0;
      }
      if (a.matchingFields[0][0] < b.matchingFields[0][0]) {
        return 1;
      } else if (a.matchingFields[0][0] > b.matchingFields[0][0]) {
        return -1;
      } else if (a.matchingFields.length > 1 && b.matchingFields.length > 1) {
        subSort(
          { ...a, matchingFields: a.matchingFields.slice(1) },
          {
            ...b,
            matchingFields: b.matchingFields.slice(1)
          }
        );
      } else {
        return 0;
      }
    };
    // Sort first by number of matching fields.
    if (first.numberOfMatches > second.numberOfMatches) {
      return -1;
    } else if (first.numberOfMatches < second.numberOfMatches) {
      return 1;
    } else {
      // Equal number of matching fields, sort by sorted list of matching fields so same matches on same fields are next to each other.
      return subSort(first, second);
    }
  }

  @wire(getSimilarCasesForCase, { caseId: "$recordId" })
  wiredCases({ error, data }) {
    if (error) {
      this.showSpinner = false;
      this.error = error;
      this.similarCasesFound = false;
    } else if (data == undefined || data.length === 0) {
      this.rows = [];
      this.showSpinner = false;
      this.similarCasesFound = false;
    } else {
      const getClassName = (caseData, fieldName) =>
        caseData[fieldName] != undefined &&
        caseData[fieldName] === thisCase[fieldName]
          ? "slds-text-color_success"
          : "";

      const fields = [
        "EbNumber",
        "email",
        "pir",
        "bookingReference",
        "flightNumber",
        "flightDate",
        "department",
        "customerClaimType"
      ];

      const getNumMatches = (caseData) =>
        fields.reduce(
          (prev, curr) =>
            caseData[curr] != undefined && caseData[curr] === thisCase[curr]
              ? prev + 1
              : prev,
          0
        );

      const getMatchingFields = (caseData) =>
        fields.reduce(
          (prev, curr) =>
            caseData[curr] != undefined && caseData[curr] === thisCase[curr]
              ? prev.concat(curr)
              : prev,
          []
        );

      const formattedCases = data.map((entry, idx) => {
        if (entry.type === "CARE_Claim__c") {
          return {
            idx,
            id: entry.claimData.Id,
            caseNumber: `CARE-${entry.claimData.Case_Id__c}`,
            date: entry.claimData.Date_Created_In_CARE__c,
            bookingReference: entry.claimData.Booking_Reference__c,
            pir: entry.claimData.PIR__c
          };
        } else {
          const caseWithClaim = entry.caseData;
          return {
            idx,
            id: caseWithClaim.Id,
            caseNumber: caseWithClaim.CaseNumber,
            bookingReference: caseWithClaim.Claims__r[0].Liability_PNR__c,
            date: caseWithClaim.CreatedDate,
            EbNumber: caseWithClaim.Claims__r[0].EuroBonus_Number__c,
            email: caseWithClaim.Claims__r[0].Contact_Email__c,
            owner: caseWithClaim.Owner.Name,
            pir: caseWithClaim.Claims__r[0].PIR__c,
            status: caseWithClaim.Status,
            flightNumber: caseWithClaim.Claims__r[0].Flight_Number__c || '',
            flightDate: caseWithClaim.Claims__r[0].Flight_Date__c || '',
            department: caseWithClaim.Department__c,
            customerClaimType: caseWithClaim.Customer_Claim_Type__c
          };
        }
      });

      const thisCase = formattedCases.filter(
        (caseWithClaim) => caseWithClaim.id === this.recordId
      )[0];

      const casesWithDisplayDetails = formattedCases
        .filter((caseWithClaim) => caseWithClaim.id !== this.recordId)
        .map((parsedCase) => ({
          ...parsedCase,
          classNameEbNumber: getClassName(parsedCase, "EbNumber"),
          classNameEmail: getClassName(parsedCase, "email"),
          classNamePir: getClassName(parsedCase, "pir"),
          classNamePnr: getClassName(parsedCase, "bookingReference"),
          classNameDepartment: getClassName(parsedCase, "department"),
          classFlightNumber: getClassName(parsedCase, "flightNumber"),
          classFlightDate: getClassName(parsedCase, "flightDate"),
          classNameCustomerClaimType: getClassName(parsedCase, "customerClaimType"),
          numberOfMatches: getNumMatches(parsedCase),
          matchingFields: getMatchingFields(parsedCase)
        }));

      this.rows = [...casesWithDisplayDetails.sort(this.sortCasesBySimilarity)];

      this.rows.forEach((row, idx) =>
        this[NavigationMixin.GenerateUrl]({
          type: "standard__recordPage",
          attributes: {
            recordId: row.id,
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
      this.similarCasesFound = true;
    }
  }
}
