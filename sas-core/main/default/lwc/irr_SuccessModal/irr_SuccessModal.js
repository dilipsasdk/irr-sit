/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description TODO
 */

import {LightningElement, api} from 'lwc';

export default class IRR_SuccessModal extends LightningElement {

    @api showSuccess;

    @api selectedCount;

    get messageText() {
        return this.selectedCount > 1 ? 'messages were' : 'message was';
    }

    get modalClass() {
        return this.showSuccess ? 'slds-modal slds-fade-in-open' : 'slds-modal';
    }

    get backdropClass() {
        return this.showSuccess ? 'slds-backdrop slds-backdrop--open' : 'slds-backdrop';
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