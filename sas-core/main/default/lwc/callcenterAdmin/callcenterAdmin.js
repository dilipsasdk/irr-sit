import { LightningElement, wire, track} from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//import all methods from CallcenterAdminController
import getContactCenterUsers from '@salesforce/apex/CallCenterAdminController.getContactCenterUsers';
import getContactCenterGroups from '@salesforce/apex/CallCenterAdminController.getContactCenterGroups';
import assignUserToContactCenterGroup from '@salesforce/apex/CallCenterAdminController.assignUserToContactCenterGroup';


export default class CallcenterAdmin extends LightningElement {
    userResult;

    selectedAgent;
    selectedGroup;
    @track searchStrings = {'agent': '', 'group': ''};
    dirty = false;

    showAgents = false;
    showGroups = false;
    showSpinner = false;

    @track users = {};
    @track groups = {};
    @track rows = [];

    get groupOptions() {
        const filteredGroups = Object.values(this.groups).map(group => ({label: group.groupName, value: group.groupId}));
        const toReturn = this.searchStrings['group'] !== '' ? filteredGroups.filter(group => group.label.toLowerCase().includes(this.searchStrings['group'].toLowerCase())) : filteredGroups;
        return toReturn.sort((a,b) => a.label.localeCompare(b.label));
    }
    get agentOptions() {
        const filteredUsers = Object.values(this.users).map(user => ({label: user.userName /*+ ' - ' + user.contactCenterGroupName*/, value: user.userId}));
        const toReturn = this.searchStrings['agent'] !== '' ? filteredUsers.filter(user => user.label.toLowerCase().includes(this.searchStrings['agent'].toLowerCase())) : filteredUsers;
        return toReturn.sort((a,b) => a.label.localeCompare(b.label));
    }

    get selectedOptions() {
        return this.rows.map(row => ({idx: row.idx,name: this.users[row.userId].userName, group: this.groups[row.groupId].groupName}));
    }        

    get cannotSave() { 
        return !this.dirty;
    }

    get currentAgentName() {
        return this.selectedAgent ? this.selectedAgent.userName : '';
    }

    get currentGroupName() {
        return this.selectedGroup ? this.selectedGroup.groupName : '';
    }


    @wire(getContactCenterGroups)
    wiredContactCenterGroups({ error, data }) {
        const groupsFound = !error && data != undefined && data.length >= 1;
        if (groupsFound) {
            this.groups = data.reduce((obj, item) => {
                obj[item.Id] = {groupName: item.Name, groupId: item.Id};
                return obj;
            }, {});
        } else {
            this.groups = {}; 
            console.log("Could not find any groups");
        }
    }

    @wire(getContactCenterUsers)
    wiredVoiceUsers(result) {
        this.userResult = result;
        const { error, data } = this.userResult;
        const usersFound = !error && data != undefined && data.length >= 1;
        if (usersFound) {
            this.users = data.reduce((obj, item) => {
                obj[item.userId] = {userName: item.userName, userId: item.userId, contactCenterGroupName: item.contactCenterGroupName, contactCenterGroupId: item.contactCenterGroupNameId};
                return obj;
            }, {});
        } else {
            this.users = {};
            console.log("Could not find any users");
        }
    }

    handleAddRow() {
        if (this.selectedAgent && this.selectedGroup) {
            this.rows = [...this.rows, {
                idx: this.rows.length === 0 ? 0 : this.rows[this.rows.length - 1].idx + 1, 
                userId: this.selectedAgent.userId, 
                groupId: this.selectedGroup.groupId
            }];
            this.selectedAgent = null;
            this.selectedGroup = null;
            this.dirty = true;
        }    
    }
    handleRemoveRow(event) {
        this.rows = this.rows.filter((row) => row.idx != event.target.dataset.idx);
        this.dirty = true;
    }

    async handleSave() {
        this.showSpinner = true;
        if(this.dirty) {
            console.log('saving');
            const dirtyDTO = this.rows.map(row => ({ userName: this.users[row.userId].userName, userId: row.userId, contactCenterGroupName: this.groups[row.groupId].groupName, contactCenterGroupNameId: row.groupId }));
            await assignUserToContactCenterGroup({ callCenterAdminDTO: dirtyDTO }).then(result => {
                this.dirty = false;
                this.rows = [];
                refreshApex(this.userResult);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Users updated successfully!",
                        variant: "success"
                    })
                );
            }).catch(error => {
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating users',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });

        }
        this.showSpinner = false;
        
    }

    handleSearch(event) {
        const input = event.detail.value.toLowerCase();
        const eventType = event.target.dataset.type;
        this.searchStrings[eventType] = input;   
      }
    
    selectSearchResult(event) {
        const eventType = event.currentTarget.dataset.type;
        if (eventType === 'group') {
            this.selectedGroup = this.groups[event.currentTarget.dataset.value];
        } else if (eventType === 'agent') {
            this.selectedAgent = this.users[event.currentTarget.dataset.value];
            if (this.selectedAgent.contactCenterGroupId) {
                this.selectedGroup = this.groups[this.selectedAgent.contactCenterGroupId];
            }
        }    
        this.clearSearchResults(eventType);
    }

    clearSearchResults(type) {
        this.searchStrings[type] = '';
        if (type === 'group') {
            this.showGroups = false;
        } else if (type === 'agent') {
            this.showAgents = false;
        }
    }

    handleOnfocus(event) {
        const eventType = event.target.dataset.type;
        if (eventType === 'group') {
            this.showGroups = true;
            return this.groupOptions;
        } else if (eventType === 'agent') {
            this.showAgents = true;
            return this.agentOptions;
        }    
    }   
}