/**
 * @author Chetan Singh, Coforge
 * @date 2022
 *
 * @description Email input panel for the Hotel accommodation Tool(Lexit).
 * Emails are being fetched from CMDT and also can be put manually by Agents.
 */


import { LightningElement,track,api } from 'lwc';
import distributionList from '@salesforce/label/c.Distribution_Lists';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendCsvEmail from "@salesforce/apex/IRR_CON_SendEmail.SendCsvEmail";
export default class IRR_HotelAccomodation extends LightningElement {

    @api emailPicklistOptions = [];

    @api selectedCount;

    @track recipients = [];

    @api isShowModal = false;

    @api paxData ;
     
    @api fileName;

    @track toAddresses = [];

    showEmailPicklist = false;

    @track isDisabledSend = false;

    idTracker = 0;

    connectedCallback() {
        for(const emailList of distributionList.split(';')){
            const option = {
                label: emailList,
                value: emailList
            };
            this.emailPicklistOptions = [ ...this.emailPicklistOptions, option ];
        }
    }

    get modalClass() {
        return this.showRecipientModal ? 'slds-modal slds-fade-in-open' : 'slds-modal';
    }

    get passengerText() {
        return this.selectedCount > 1 ? 'Passengers' : 'Passenger' ;
    }
    handleEmailChange(event) {

        const {name , value , dataset: {recipientIndex} } = event.target;
        this.toAddresses[recipientIndex][name] = value;

    }
    handleChange(event) {
        this.recipients.push(event.detail.value);
    }
    showModalBox() {
        this.isShowModal = true;
    }

    hideModalBox() {
        this.isShowModal = false;
        const sendEvent = new CustomEvent('closehotelacc', {
            detail: false
        });
        this.dispatchEvent(sendEvent);

    }
    validateFields() {
        return [...this.template.querySelectorAll('lightning-input')]
            .reduce((previousValue, cmp) => cmp.reportValidity() && previousValue, true);
    }

    handleCancel(){
        this.isShowModal = false;
        const sendEvent = new CustomEvent('closehotelacc', {
            detail: false
        });
        this.dispatchEvent(sendEvent);
    }

    handleAdd() {
        const idNumber = ++this.idTracker;
        this.toAddresses.push({ id: `rec${idNumber}`});
    }

    handleSend(){
        if (!this.validateFields()) return; 

        this.toAddresses.forEach ( (address) => {
            this.recipients.push(address.emailAddress);

        })

         if(this.recipients === '' || this.recipients === undefined){
            const toastEvent = new ShowToastEvent({
                title: 'No Address Selected',
                message: 'Please select an email.',
            });
            this.dispatchEvent(toastEvent);
            return ;
         }
         this.isDisabledSend = true;
         sendCsvEmail({PaxData: this.paxData, FileName: this.fileName, SendTo : this.recipients }).then(result => {
            const toastEvent = new ShowToastEvent({
                title: 'Send successfuly',
                message: 'Email(s) have been sent successfuly.',
            });
            this.dispatchEvent(toastEvent);
            this.isShowModal = false;
            const sendEvent = new CustomEvent('closehotelacc', {
                detail: false
            });
            this.dispatchEvent(sendEvent);
           })
           .catch(error => {
            this.handleError(error, true);
        });
    }
}