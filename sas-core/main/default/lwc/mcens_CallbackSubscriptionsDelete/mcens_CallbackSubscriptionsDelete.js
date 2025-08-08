import { LightningElement, api, track } from 'lwc';
import deleteSubscription from "@salesforce/apex/MCENS_SubscriptionService.deleteSubscription";

export default class Mcens_CallbackSubscriptionsDelete extends LightningElement {
    /**
     * THe id of the subscription to delete
     */
    @api subscriptionId;
    /**
     * Whether the dialog is waiting for input from the server
     */
    @track isWaiting = false;
    /**
     * Error object for an error which occured
     */
    @track error = null;

    /**
     * Called to cancel the dialog
     */
    async deleteSubscription(){
        try{
            this.error = null;
            this.isWaiting = true;
            await deleteSubscription({
                subscriptionId : this.subscriptionId, 
            });
            this.dispatchEvent(new CustomEvent('deleted'));
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