/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description TODO
 */

import {LightningElement, api, track} from 'lwc';

export default class IRR_RecipientModal extends LightningElement {

    @api showRecipientModal;

    @api selectedRecipients;

    @api
    reset() {
        this.recipients = [];
    }

    @track recipients = [];

    idTracker = 0;

    get modalClass() {
        return this.showRecipientModal ? 'slds-modal slds-fade-in-open' : 'slds-modal';
    }

    get backdropClass() {
        return this.showRecipientModal ? 'slds-backdrop slds-backdrop--open' : 'slds-backdrop';
    }

    handleSave() {
        if (!this.validateFields()) return;
        const event = new CustomEvent('updaterecipients', { detail: JSON.parse(JSON.stringify(this.recipients)) });
        this.dispatchEvent(event);
    }

    validateFields() {
        return [...this.template.querySelectorAll(`lightning-input[data-input-group="additionalRecipient"]`)]
            .reduce((previousValue, cmp) => cmp.reportValidity() && previousValue, true);
    }

    handleChange(event) {
        const { name, value, dataset: { recipientIndex } } = event.target;
        this.recipients[recipientIndex][name] = value;
    }

    handleRemove(event) {
        const index = parseInt(event.currentTarget.dataset.recipientIndex);
        this.recipients.splice(index, 1);
    }

    handleAdd() {
        const idNumber = ++this.idTracker;
        this.recipients.push({ id: `rec${idNumber}`});
    }

    @api
    handleCancel() {
        this.recipients = JSON.parse(JSON.stringify(this.selectedRecipients));
        const event = new CustomEvent('hiderecipientmodal');
        this.dispatchEvent(event);
    }
}