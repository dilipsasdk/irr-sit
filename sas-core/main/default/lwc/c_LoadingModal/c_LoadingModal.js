/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description Simple loading modal LWC.
 */

import {LightningElement, api} from 'lwc';

export default class C_LoadingModal extends LightningElement {

    @api loadCount;

    get showSpinner() {
        return this.loadCount > 0;
    }

    get backdropClass() {
        return this.loadCount > 0 ? 'slds-backdrop slds-backdrop_open' : 'slds-backdrop'
    }

    get sectionClass() {
        return this.loadCount > 0 ? 'slds-modal slds-fade-in-open' : 'slds-modal';
    }
}