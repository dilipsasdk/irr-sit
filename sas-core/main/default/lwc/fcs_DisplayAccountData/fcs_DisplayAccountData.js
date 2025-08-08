/**
 * @author Anton Norell
 * @date 2020-02-18
 * @description Contains client side logic to support component to display account data
 */
import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
export default class FCS_DisplayPersonAccount extends NavigationMixin(LightningElement) {
  @api accountid;

  /**
   * Used to direct user to a record page for account in Salesforce. Uses class variable accountid
   */
  navigateToRecordViewPage() {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: this.accountid,
        objectApiName: 'Account',
        actionName: 'view'
      }
    });
  }
}