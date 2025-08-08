import { LightningElement, api, track, wire } from 'lwc';
import findCase from "@salesforce/apex/FCS_CaseTag_Controller.findCase";

export default class Fcs_caseTagEndCallListener extends LightningElement {
    @api recordId;
    @track isModalOpen=false;
    @track callEndedFlag = false;
    @track caseTagged = false;

    renderedCallback() {
        this.subscribeToVoiceToolkit();
    }

    @wire(findCase, {
        recordId: "$recordId"
      })
      wiredcse(result) {
        this.wiredCaseList = result;
        if (result.data) {
          this.cse = result.data;
          if (this.cse && this.cse.Id) {
            if (this.cse.FCS_Case_Reason__c) {
              this.caseTagged = true;
            }
          }
        } else if (result.error) {
          this.displayError(result.error);
        }
      }

    constructor() {
        super();
        this.telephonyEventListener = this.onTelephonyEvent.bind(this);
    } 

    get caseId() {
        return getFieldValue(this.caseObj.data, CASE_FIELD);
    }

    onTelephonyEvent(event) {
        if (event.type === 'callended' && this.callEndedFlag == false && this.caseTagged == false) {
            this.telephonyActionControlsDisabled = true;
            this.callEndedFlag = true;
            this.openModal();
        }
        this.teleEvent = event.type;
    }

    subscribeToVoiceToolkit() {
        const toolkitApi = this.getToolkitApi();
        toolkitApi.addEventListener('callended', this.telephonyEventListener);
    }

    getToolkitApi() {
        return this.template.querySelector('lightning-service-cloud-voice-toolkit-api');
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }
}