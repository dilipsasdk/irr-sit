import { LightningElement, api } from 'lwc';

export default class Mcens_CallbackSubscriptionsError extends LightningElement {
    /**
     * The error object, which can eb a javscript exception or a server side apex exception
     */
    @api error;
    /**
     * Generates a JSON string of the error object
     */
    get errorMessage() {
        return JSON.stringify(this.error);
    }
}