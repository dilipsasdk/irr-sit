/**
 * @author Anton Norell
 * @description JS controller for component used to display queue status to an agent in Salesforce
 * @date 2020-04-20
 */
import { LightningElement, track, api } from "lwc";
import userId from '@salesforce/user/Id';
import locale from '@salesforce/i18n/locale'
import getQueueIds from '@salesforce/apex/FCS_OmniChannelQueueBacklogController.getQueueIds';
import getQueueStatus from '@salesforce/apex/FCS_OmniChannelQueueBacklogController.getQueueStatus';

const columns = [
  { label: 'Queue', fieldName: 'queueName', wrapText: true},
  { label: 'Waiting', fieldName: 'countWaiting', type: 'number', cellAttributes: { alignment: 'left' }},
  { label: 'Longest wait time', fieldName: 'longestWaitTime'}
  ];

export default class FCS_OmniChannelQueueBacklog extends LightningElement {
  /**
   * List of queue ids to retrieve status for. This parameter is set when to component is initialized and used when refreshing the list of queue statuses.
   */
  queueIds = undefined;
  /**
   * Indicates that a spinner graphic should show in the component when set to true,
   */
  showSpinner = false;
  /**
   * List of queues with a status for each. Data shown in the data table in the component.
   */
  queueStatus = undefined;
  /**
   * Defines columns shown in the lightning datatable in the component
   */
  columns = columns;
  /**
   * Indicates that an error has occurred and should be shown in the component.
   */
  @api error = undefined;
  /**
   * Datetime storing the values for when the data in the component was last refreshed. Used to display value in component.
   */
  lastRefreshed;

  /**
   * Method running when the component is inserted into the DOM. Performs a first data refresh.
   */
  connectedCallback() {
    this.dispatchEvent(new CustomEvent('componentInitiated'));
    this.refreshQueueStatus();
  }

  /**
   * Used to populate data in the component. First retrieves list of queue ids that the current user is a member of,
   * if the value has not been set before. Then the status for those queues are retrieved.
   * @returns List of queue statuses in custom format (see controller).
   */
  @api async refreshQueueStatus(){
    console.log('Running refresh');
    this.error = undefined;
    this.showSpinner = true;
    try{
      if(!this.queueIds){
        this.queueIds = await getQueueIds({userId: userId});
      }
      if (this.queueIds){
        this.queueStatus = await getQueueStatus({queueIds: this.queueIds});
      }
      this.showSpinner = false;
      this.lastRefreshed = new Date().toLocaleString(locale);
    } catch (error) {
      this.displayError(error);
    }
  }

  /**
   * Used to set parameters to display en error to the user.
   * @param error Error to display.
   */
  displayError(error) {
    console.log("An error occurred: " + JSON.stringify(error));
    this.showSpinner = false;
    this.error = error;
  }
}