/**
 * @author Chetan Singh, Coforgetech
 * @date 2020
 *
 * @description TODO
 */

import {LightningElement, api} from 'lwc';

export default class IRR_ScheduleMessage extends LightningElement {

    @api showScheduleSuccess;

    @api selectedCount;

    get messageText() {
        return this.selectedCount > 1 ? 'messages were' : 'message was';
    }

    get modalClass() {
        return this.showScheduleSuccess ? 'slds-modal slds-fade-in-open' : 'slds-modal';
    }

    get backdropClass() {
        return this.showScheduleSuccess ? 'slds-backdrop slds-backdrop--open' : 'slds-backdrop';
    }

    handleClose() {
        const event = new CustomEvent("hidesuccess");
        this.dispatchEvent(event);
    }

    handleNewSearch() {
        const event = new CustomEvent("newsearch");
        this.dispatchEvent(event);
    }
}