import { LightningElement,track,wire } from 'lwc';
import getActiveQRCount from '@salesforce/apex/IRR_CON_SendQRForLoungeAccess.getActiveQRCount';
import sendEmailToCustomer from '@salesforce/apex/IRR_CON_SendQRForLoungeAccess.sendEmailToCustomer';
import { refreshApex } from '@salesforce/apex';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
export default class Irr_SendQRForLoungeAccess extends LightningElement {

 
    @track emails = [];
    firstTime = true;
    EmailKeyTracker = 0;
    showSuccess = false;
    activeQRCount;
    expiryDate;
    error;
    isEmailSent = false;
    recipientCount = 1;
    _wiredRefreshData;

    connectedCallback() {
        if(this.firstTime) {
            this.handleEmailsAdd();
        }
         
    }
   
    @wire(getActiveQRCount)
    getQRCount(wireResult) {
         const { data, error } = wireResult;
         this._wiredRefreshData = wireResult;
        if (data) {
            this.activeQRCount = data[0].totalCount;
            this.expiryDate = data[0].expiryDate__c;
            this.error = undefined;
        } else if (error) {
            
            this.error = error;
            console.log('method call2'+this.error);
        }
        else{
            this.activeQRCount = 0;
            this.expiryDate = '00-00-0000';
        }
    }
    renderedCallback(){
     const adobeButton = this.template.querySelector(`[data-id = "0"]`);
      adobeButton.className = "slds-hide"; 
    }
    handleEmailsAdd() {
        const emailKey = ++this.EmailKeyTracker;
            if(this.firstTime) {
                 this.firstTime = false;
                 this.emails.push( { key: `email-${emailKey}`, emailAddress: `` ,caseId:``,comment:`` } );
            } else {
           this.emails.push( { key: `email-${emailKey}`, emailAddress: `` ,caseId:`` ,comment:``} );
            }       
    }
    handleEmailRemove(event){
        const index = parseInt(event.currentTarget.dataset.emailIdx);
        this.emails.splice(index, 1);
    }

    handleEmailChange(event) {
      
      const { name, value, dataset: { emailIdx } } = event.target;
      if(event.target.name == "Email"){
      this.emails[emailIdx].emailAddress = value;
      }
    if(event.target.name == "caseId"){
      this.emails[emailIdx].caseId = value;
      }
    if(event.target.name == "comment"){
      this.emails[emailIdx].comment = value;
      console.log('-comment---->'+this.emails[emailIdx].comment);
      }
    }
     handleSendQR(){
        
        for(let i=0; i<this.emails.length; i++){
          if(this.emails[i].emailAddress =='' || this.emails[i].caseId == ''){
               this.dispatchEvent(
                  new ShowToastEvent({
                      title: 'Error!!',
                      message: 'Please Check Row: '+(i+1)+', Email or Case Number fields should not be blank !!! ',
                      variant: 'Error',
                      mode: 'Sticky'
                    })
                );
              return;
          }
          
        }
        
        //send data to controller
          sendEmailToCustomer({emailList:this.emails})
            .then(result => {
                console.log('result-------', result);
                this.isEmailSent = true;
                 this.showSuccess = true;
                 refreshApex(this._wiredRefreshData); 
            })
            .catch(error => {
                console.log('this.createError' + error);
                
            });

    }
    handleevent(event){
        if(event.detail==true){
            refreshApex(this._wiredRefreshData);
        }

    }
    handleRevertToMainComponent(){
         for (var j = 0; j < this.emails.length; j++){
            this.emails[j].emailAddress='';
            this.emails[j].caseId='';
            this.emails[j].comment='';
        }
        this.showSuccess = false;
    }
    handleChange(event) {
        let selectedEvent = new CustomEvent('valueselected', {detail: event.detail.value[0]});
        this.dispatchEvent(selectedEvent);  
    }
    enableModelFlag(){
        this.template.querySelector("c-irr_-lounge-access-c-s-v-uploader").setModelFlag();
    }
  
}