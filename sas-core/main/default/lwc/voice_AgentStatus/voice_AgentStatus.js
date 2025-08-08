import { LightningElement, wire, api, track } from 'lwc';
import getAgentPresenceOverview from '@salesforce/apex/Voice_AgentStatusController.getAgentPresenceOverview';
import getAgentCallOverview from '@salesforce/apex/Voice_AgentStatusController.getAgentCallOverview';
import getTotalCallOverview from '@salesforce/apex/Voice_AgentStatusController.getTotalCallOverview';
import { refreshApex } from '@salesforce/apex';

const presence_columns = [
    { label: 'Presence', fieldName: 'presence', type: 'text' },
    { label: 'Duration', fieldName: 'durationFormatted', type: 'text' }
];

const calls_columns = [
    { label: 'Queuename', fieldName: 'queueName', type: 'text' },
    { label: 'Offered Calls', fieldName: 'offeredCalls', type: 'text' },
    { label: 'Dropped Calls', fieldName: 'droppedCalls', type: 'text' }
];

export default class Voice_AgentStatus extends LightningElement {
    agentPresencesOverview;
    agentPresencesOverviewWired;
    agentCallOverview;
    agentCallOverviewWired;
    totalCallOverview;
    totalCallOverviewWired;
    lastRefreshed = new Date();
    showSpinner = true;
    presence_columns = presence_columns;
    calls_columns = calls_columns;

    @wire(getAgentPresenceOverview)
    wiredAgentStatus(result) {
        this.showSpinner = true;
        this.agentPresencesOverviewWired = result;
        if (result.data) {
            this.agentPresencesOverview = result.data;
        } else if (result.error) {
            console.error(result.error);
        }
        this.showSpinner = false;
    }

    @wire(getAgentCallOverview)
    wiredAgentCallsOverview(result) {
        this.showSpinner = true;
        this.agentCallOverviewWired = result;
        if (result.data) {
            this.agentCallOverview = result.data;
        } else if (result.error) {
            console.error(result.error);
        }
        this.showSpinner = false;
    }

    @wire(getTotalCallOverview)
    wiredAgentTotalCalls(result) {
        this.showSpinner = true;
        this.totalCallOverviewWired = result;
        if (result.data) {
            this.totalCallOverview = result.data;
        } else if (result.error) {
            console.error(result.error);
        }
        this.showSpinner = false;
    }

    // When the refresh  utton is clicked or when the utitliybar button is clicked
    // reload the data
    @api handleRefresh() {
        this.showSpinner = true;
        Promise.all([
            refreshApex(this.agentPresencesOverviewWired), 
            refreshApex(this.agentCallOverviewWired), 
            refreshApex(this.totalCallOverviewWired)])
        .then((values) => {
            this.lastRefreshed = new Date();
            this.showSpinner = false;
        })
        .catch((error) => {
            console.error(error.message);
            this.showSpinner = false;
        });
    }

    // When the component is loaded, fire the componentInitiated event, that will trigger
    // code on the hosting AURA component
    connectedCallback() {
        this.showSpinner = true;
        this.dispatchEvent(new CustomEvent('componentInitiated'));
    }
}