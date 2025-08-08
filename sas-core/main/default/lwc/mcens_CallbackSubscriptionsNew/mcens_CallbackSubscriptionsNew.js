import { LightningElement, api, track } from 'lwc';
import createSubscriptionForRecord from "@salesforce/apex/MCENS_SubscriptionService.createSubscriptionForRecord";

export default class Mcens_CallbackSubscriptionsNew extends LightningElement {
    /**
     * The id of the callback record for which to create the subscription record
     */
    @api callbackId;
    /**
     * Whether the dialog is waiting for input from the server
     */
    @track isWaiting = false;
    /**
     * Error object for an error which occured
     */
    @track error = null;
    /**
     * Validates the input and creates a subscription for the callback
     */
    create(){
        let subName = this.template.querySelector("lightning-input[data-id='subName']");
        let subEventCatTypes = this.template.querySelector("lightning-textarea[data-id='subEventCatTypes']");
        let subFilters = this.template.querySelector("lightning-textarea[data-id='subFilters']");
        subName.reportValidity();
        subEventCatTypes.reportValidity();
        subFilters.reportValidity();
        if(subName.checkValidity() && subEventCatTypes.checkValidity() && subFilters.checkValidity()){
            let evtCatTypes = subEventCatTypes.value!=null && subEventCatTypes.value.trim()!="" ? subEventCatTypes.value.trim().split(",") : [];
            for(let i=0;i<evtCatTypes.length;i++){
                evtCatTypes[i] = evtCatTypes[i].trim();
            }
            let filters = subFilters.value!=null && subFilters.value.trim()!="" ? subFilters.value.trim().split(",") : [];
            for(let i=0;i<filters.length;i++){
                filters[i] = filters[i].trim();
            }
            this.createSubscription(subName.value,evtCatTypes,filters);
        }
    }
    /**
     * Creates a subscription for the callback
     * @param {string} subName 
     * @param {*} evtCatTypes 
     * @param {*} subFilters 
     */
    async createSubscription(subName, evtCatTypes, filters){
        try{
            this.error = null;
            this.isWaiting = true;
            let sub = await createSubscriptionForRecord({
                callbackRecordId : this.callbackId, 
                subscriptionName : subName,
                eventCategoryTypes : evtCatTypes,
                filters : filters
            });
            this.dispatchEvent(new CustomEvent('created'));
        } catch (error) {
            this.isWaiting = false;
            this.error = error;
        }
    }
    /**
     * Called to cancel the dialog
     */
    cancel(){
        this.dispatchEvent(new CustomEvent('canceled'));
    }
}