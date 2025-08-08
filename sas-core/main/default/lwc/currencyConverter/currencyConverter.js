import { LightningElement, wire, api } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import SETTLEMENT_CURRENCY_FIELD from "@salesforce/schema/Settlement__c.Currency__c";

import getAllExchangeRates from "@salesforce/apex/SettlementsController.getAllExchangeRates";

/**
 * A currency converter component which can be added to any record page.
 *
 * Uses Exchange_Rate__c records to do the conversions.
 */
export default class CurrencyConverter extends LightningElement {
  @api recordId;
  @api objectApiName;

  fromCurrency = "EUR";
  toCurrency = "SEK";
  amount = 250;

  get fromOptions() {
    return this.availableCurrencies.filter((x) => x.value != this.toCurrency);
  }

  get toOptions() {
    return this.availableCurrencies.filter((x) => x.value != this.fromCurrency);
  }

  get result() {
    if (
      this.exchangeRates &&
      this.exchangeRates[this.fromCurrency] &&
      this.exchangeRates[this.fromCurrency][this.toCurrency]
    ) {
      // Rounded to 2 decimals.
      return Math.round(
        (this.amount *
          this.exchangeRates[this.fromCurrency][this.toCurrency] *
          100) /
          100
      );
    } else {
      return 0;
    }
  }

  showSpinner = true;
  error = undefined;

  exchangeRates;
  availableCurrencies = [];

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [SETTLEMENT_CURRENCY_FIELD]
  })
  wiredSettlement({ error, data }) {
    if (!error && data) {
      if (this.objectApiName === "Settlement__c") {
        if (data.recordTypeInfo.name !== "EB points") {
          // Default to the settlement's currency for to currency.
          this.toCurrency = data.fields.Currency__c.value;
        }
      }
    }
  }

  @wire(getAllExchangeRates)
  getAllExchangeRates({ error, data }) {
    const ratesFound = !error && data != undefined && data.length > 0;
    if (ratesFound) {
      /**
       * Build an object of form
       * {
       *   sek: {
       *     eur: 9.82, // sek to eur rate
       *     nok: 1.1
       *   },
       *   usd: {
       *     dkk: 1
       *   }
       * }
       */
      this.exchangeRates = data.reduce((acc, curr) => {
        const existingFromObject = acc[curr.From_Currency__c] || {};
        const newFromObject = {
          ...existingFromObject,
          [curr.To_Currency__c]: curr.Rate__c
        };

        return {
          ...acc,
          [curr.From_Currency__c]: newFromObject
        };
      }, {});
      this.availableCurrencies = Object.keys(this.exchangeRates).map(
        (currency) => ({ value: currency, label: currency })
      );
      this.showSpinner = false;
    }
    this.error = error;
    this.showSpinner = false;
  }

  handleFromChange(event) {
    this.fromCurrency = event.target.value;
  }

  handleToChange(event) {
    this.toCurrency = event.target.value;
  }

  handleAmountChange(event) {
    this.amount = event.target.value;
  }
}
