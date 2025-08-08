import { LightningElement, api, track } from 'lwc';
import getSubscriptionsForRecord from "@salesforce/apex/MCENS_SubscriptionService.getSubscriptionsForRecord";

export default class Mcens_CallbackSubscriptions extends LightningElement {
    /**
     * Record Id for the callback record for which this component is displayed
     * @type {string}
     */
    @api recordId;
    /**
     * When true, spinner graphic is displayed over component
     * @type {boolean}
     */
    @track showSpinner = true;
    /**
     * The list of subscriptions for the callback record
     */
    @track subscriptionList = [];
    /**
     * Errors which occurs when fetching the subscriptions
     */
    @track error;
    /**
     * When, true displays the modal for creating a new subscription
     */
    @track showNewSubscriptionDialog = false;
    /**
     * Sets when in the contet to delete a subscription
     */
    @track deleteSubscriptionId = null;

    /**
     * Method running when component is inserted in DOM
     * Refreshes the subscriptions for the callback
     */
    connectedCallback() {
        this.refreshSubscriptions();
    }

    /**
     * Refreshes the subscriptions for the callback to enable them to be displayed
     */
    async refreshSubscriptions(){
        try{
            this.showSpinner = true;
            let subList = JSON.parse(JSON.stringify(await getSubscriptionsForRecord({ callbackRecordId: this.recordId })));
            for(let sub of subList){
                sub.eventCategoryTypesFlat = '';
                sub.filtersFlat = '';
                if(sub.eventCategoryTypes){
                    for(let evt of sub.eventCategoryTypes){
                        if(sub.eventCategoryTypesFlat!='')sub.eventCategoryTypesFlat+=', ';
                        sub.eventCategoryTypesFlat+=evt;
                    }
                }
                if(sub.filters){
                    for(let f of sub.filters){
                        if(sub.filtersFlat!='')sub.filtersFlat+=', ';
                        sub.filtersFlat+=f;
                    }
                }
            }
            this.subscriptionList = subList;
            this.clearError();
            this.showSpinner = false;
        } catch (error) {
            this.displayError(error);
        }
    }

    /**
     * Used to set parameters to display en error to the user.
     * @param error The error to display
     */
    displayError(error) {
        console.log("An error occurred: " + JSON.stringify(error));
        this.showSpinner = false;
        this.error = error;
    }

    /**
     * Clears the displayed error
     */
    clearError(){
        if(this.error)this.error=null;
    }
    /**
     * Called when the user clicks the button to create a new subscription.
     * Opens the new subscription dialog
     */
    openNewSubscriptionDialog(){
        this.showNewSubscriptionDialog = true;
    }

    /**
     * Called when closing the dialog to create a new subscription without creating a new subscription
     */
    newSubscriptionCanceled(){
        this.showNewSubscriptionDialog = false;
    }
    /**
     * Called to create a new subscription
     */
    newSubscriptionCreated(){
        this.showNewSubscriptionDialog = false;
        this.refreshSubscriptions();
    }
    /**
     * Called when the user click a button to delete a subscription
     */
    openDeleteSubscriptionDialog(evt){
        this.deleteSubscriptionId=evt.srcElement.getAttribute("data-subid");
    }
    /**
     * Called when the prompt to delete a subscription was canceled
     */
    deleteSubscriptionCanceled(){
        this.deleteSubscriptionId = null;
    }
    /**
     * Called when a subscription was deleted
     */
    subscriptionDeleted(){
        this.deleteSubscriptionId = null;
        this.refreshSubscriptions();
    }
}