/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description TODO
 */

import {LightningElement, api} from 'lwc';

export default class C_ErrorModal extends LightningElement {
    @api errors = [];
    @api critical;

    get modalClass() {
        return this.errors.length > 0 ? 'slds-modal slds-modal--prompt slds-fade-in-open' : 'slds-modal slds-modal--prompt';
    }

    get allowCancel() {
        return !this.critical;
    }

    get backdropClass() {
        return this.errors.length > 0 ? 'slds-backdrop slds-backdrop--open' : 'slds-backdrop';
    }

    handleReload() {
        window.location.reload();
    }

    handleCancel() {
        const event = new CustomEvent('clearerrors');
        this.dispatchEvent(event);
    }
}