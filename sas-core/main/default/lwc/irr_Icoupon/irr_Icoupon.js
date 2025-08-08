/**
 * @author Chetan Singh, Coforge
 * @date 2022
 *
 * @description Icoupon Voucher Creation input panel for the IRR Agents .
 * 
 */

import { LightningElement, api, track } from 'lwc';
import sendIcouponManualCommunication from '@salesforce/apex/IRR_CON_ManualCommunication.sendIcouponManualCommunication';
import sendStanaloneIcouponManualCommunication from '@salesforce/apex/IRR_CON_ManualCommunication.sendStandaloneIcouponManualCommunication';
import getManualIcouponMetadata from "@salesforce/apex/IRR_CON_ManualCommunication.getManualIcouponMetadata";
import getCommunicationLogsByFlightIdIcoupon from "@salesforce/apex/IRR_CON_ManualCommunication.getCommunicationLogsByFlightIdIcoupon";
import getStandaloneIcouponMetadata from '@salesforce/apex/IRR_CON_ManualCommunication.getStandaloneICouponMetadata';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getIcouponMetadata from "@salesforce/apex/IRR_CON_ManualCommunication.getIcouponMetadata";
import LightningConfirm from "lightning/confirm";
import LightningAlert from "lightning/alert";
export default class IRR_Icoupon extends LightningElement {
    @track stopSuccessAlert = false;
    @track icouponMetadata =[];
    @api showIcouponModal = false;
    @track payload = {};
    @track countExistingComm = 0;
    causingAirlineCode = 'SK';
    RedemptionPassDetails = {};
    boardingSequences = [];
    currencyCodeOptions = [];
    selectedCurrencyCode = '';
    icouponAmountOptions = [];
    selectedIcouponAmount = '';
    reasonCommentOptions = [];
    selectedReasonComment = '';
    iCouponManual = [];
    //Standalone icoupon variables
	selectedStandaloneAirport = '';
    selectedStandaloneVoucher = '';
    selectedStandaloneReason = '';
    standaloneICouponManual = [];
    standaloneIcouponVouchers = [];
    standaloneIcouponAirportCodes = [];
    standaloneIcouponReasons = [];
    isStandaloneIcouponReasonsDisbled = false;

    @api paxInfo;
    @api includedBoardedPass = false;

    connectedCallback() {
        this.onLoad();
    }

    // send the value of showIcouponModal as false to Parent component

    handleCancel() {
        this.showIcouponModal = false;
        const hideModalEvent = new CustomEvent('hideicouponmodal', {
            detail: false
        });
        this.dispatchEvent(hideModalEvent);

    }

    @api
    icouponPassengerData(passengerInfo, serviceClass) {
        this.value = serviceClass;
        this.paxInfo = passengerInfo;

    }

    handleConfirm() {
        let flag = false;
        for (let pass of this.paxInfo) {
                    if( pass.hasThisSegment == true &&
                        pass.thisSegment.serviceClass != null && 
                        pass.thisSegment.boardingSequenceNumber != null && 
                        ( 
                            (pass.thisSegment.statusCode == 'HK' && pass.thisSegment.checkInStatus == 'Accepted') || 
                            (pass.thisSegment.statusCode == 'TK' && pass.thisSegment.checkInStatus == 'Accepted') || 
                            (pass.thisSegment.statusCode == 'HK' && pass.thisSegment.checkInStatus == 'StandBy')  ||
                            (pass.thisSegment.statusCode == 'TK' && pass.thisSegment.checkInStatus == 'StandBy')  
                        )){
                            flag = true;
                    }
              
            
           
        }
         if(flag == false){
            const toastEvent = new ShowToastEvent({
                title: 'Error',
                message: 'None of the selected passenger met the icoupon criteria',
            });
            this.dispatchEvent(toastEvent);
            return;
         }


        const hideModalEvent = new CustomEvent('hideicouponmodal', {
            detail: {
                passengerInfo: this.paxInfo,
                voucherAmount: parseInt(this.selectedIcouponAmount),
                currencyCode: this.selectedCurrencyCode,
                reasonComment: this.selectedReasonComment,
                isIncludedBoarded: this.includedBoardedPass
            }
        });
        this.dispatchEvent(hideModalEvent);
       // this.showIcouponModal = false
        this.includedBoardedPass = false;

    }

    handleCurrencyChange(event) {
        this.icouponAmountOptions = [];
        this.selectedIcouponAmount = '';
        this.selectedCurrencyCode = event.detail.value;
        this.iCouponManual.forEach(item => {
            const currencyCode = item['IRR_Currency_Code__c'];
            const currencyType = item['Type__c'];
            const voucherAmount = item['IRR_Voucher_Amount__c'];

            if (currencyType === 'Amount' && currencyCode === this.selectedCurrencyCode) {
                this.icouponAmountOptions.push({ label: voucherAmount, value: String(voucherAmount) });
            }

        });
        this.icouponAmountOptions.sort((a, b) => (parseInt(a.value) > parseInt(b.value)) ? 1 : -1);
    }

    handleIncludedBoardedPassChange(event) {

        this.includedBoardedPass = event.target.checked;

    }
    handleReasonCommentChange(event) {
        this.selectedReasonComment = event.detail.value;
    }
    handleVoucherAmountChange(event) {
        this.selectedIcouponAmount = event.detail.value;
    }

    handleStandaloneIcoupon(event){
      let name = event.detail.name;
      let value =  event.detail.value;
      if(name = 'StandaloneAirportCode'){
        this.selectedStandaloneAirport = value;
      }
      else if(name = 'StandaloneVoucher'){
        this.selectedStandaloneVoucher = value;
      }
      else if(name = 'StandaloneReasonComment'){
        this.selectedStandaloneReason = value;
      }


    }

    loadICoupon() {
        getManualIcouponMetadata()
            .then(metadata => {
                this.iCouponManual = metadata;
                console.log(JSON.stringify(this.iCouponManual));
                metadata.forEach(item => {

                    const currencyCode = item['IRR_Currency_Code__c'];
                    const type = item['Type__c'];
                    if (type === 'Currency') {
                        this.currencyCodeOptions.push({ label: currencyCode, value: currencyCode });
                    }


                    const reasonComment = item['IRR_Reason_Comment__c'];
                    if (reasonComment && !this.reasonCommentOptions.some(opt => opt.value === reasonComment)) {
                        this.reasonCommentOptions.push({ label: reasonComment, value: reasonComment });
                    }
                    this.reasonCommentOptions.sort((a, b) => a.label.localeCompare(b.label));
                    /*   const voucherAmount = item['IRR_Voucher_Amount__c'];
                      if (voucherAmount && !this.icouponAmountOptions.some(opt => opt.value === String(voucherAmount))) {
                          this.icouponAmountOptions.push({ label: voucherAmount, value: String(voucherAmount)});
                      }  */




                });

            })
            .catch(error => {
                this.error = error;
            });
    }

/* Standalone iCoupon code starts here */
//new method for standalone icoupon to handle if the airport code is changed
handleAirportChange(event){
    this.standaloneIcouponVouchers = [];
    this.selectedStandaloneAirport = event.detail.value;
   if(event.detail.value === 'CPH-LOUNGE'){
     this.selectedStandaloneReason ='CPH Lounge Overflow';
     this.standaloneICouponManual.forEach(item => {
        const reasonComment = item['IRR_Reason__c'];
        const reasonId = 0;

        if (reasonComment === this.selectedStandaloneReason){
            this.reasonId = item['UniqueID__c'];
        }
    });
     this.isStandaloneIcouponReasonsDisbled = true;
    }
    else{
        this.isStandaloneIcouponReasonsDisbled = false;
        this.selectedStandaloneReason  = '';
    }
    
        this.standaloneICouponManual.forEach(item => {
        if(!(item['IRR_Airport_List__c'] === undefined)){
        const listAirportCodes = item['IRR_Airport_List__c'];
        const airportCodes = listAirportCodes.split(",");
        const type = item['Type__c'];
        const voucherProfile = item['IRR_Voucher_Profile__c'];

        airportCodes.forEach(airportCode => {
        if (type === 'Voucher' && airportCode === this.selectedStandaloneAirport) {
            this.standaloneIcouponVouchers.push({ label: voucherProfile, value: voucherProfile });
        }
    });
            this.standaloneIcouponVouchers.sort((a, b) => (parseInt(a.value) > parseInt(b.value)) ? 1 : -1);
    }

    });
    

}

//new method for standalone icoupon to handle if the Reason is changed
handleReasonChange(event) {
    this.selectedStandaloneReason = event.detail.value;
    this.standaloneICouponManual.forEach(item => {
        const reasonComment = item['IRR_Reason__c'];
        const reasonId = 0;

        if (reasonComment === this.selectedStandaloneReason){
            this.reasonId = item['UniqueID__c'];
        }
    });
}

//new method for standalone icoupon to handle if the Voucher Profile is changed
handleVoucherChange(event) {
    this.selectedStandaloneVoucher = event.detail.value;
    this.standaloneICouponManual.forEach(item => {
        const voucherProfile = item['IRR_Voucher_Profile__c'];
        //const voucherProfileId = 0;
        const voucherAmount = 0;
        const voucherCurrency = '';

        if (voucherProfile === this.selectedStandaloneVoucher){
            //this.voucherProfileId = item['UniqueID__c'];
            this.voucherAmount = item['IRR_Voucher_Amount__c'];
            this.voucherCurrency = item['IRR_Voucher_Currency__c'];
        }
    });
}

    onLoad(){
        this.icouponMetadataOnLoad();
        this.loadICoupon();
        this.loadStandalone();
    } 
    
    //new method for standalone icoupon to load all the metadata and populate drop down values
    loadStandalone(){
        getStandaloneIcouponMetadata()
            .then(metadata => {
                this.standaloneICouponManual = metadata;
                console.log(JSON.stringify(this.standaloneICouponManual));
                metadata.forEach(item => {
                    if(!(item['IRR_Airport_List__c'] === undefined)){
                    const listAirportCodes = item['IRR_Airport_List__c'];
                    const airportCodes = listAirportCodes.split(",");

                        airportCodes.forEach(airportCode => {
                        if (!this.standaloneIcouponAirportCodes.some(option => option.label === airportCode && option.value === airportCode)) {
                            this.standaloneIcouponAirportCodes.push({ label: airportCode, value: airportCode });
                        }
                    });
                }
                    const reasonComment = item['IRR_Reason__c'];
                    const type = item['Type__c']; 
                    if (type === 'Reason' && reasonComment){
                        this.standaloneIcouponReasons.push({ label: reasonComment, value: reasonComment });
                    }
                });
                            this.standaloneIcouponAirportCodes.sort((a, b) => a.label.localeCompare(b.label));
                           
                           
            })
            
            .catch(error => {
                this.error = error;
            });
    }

    async  submitStandaloneIcoupon(){

        const validationMessages = [
            { value: this.selectedStandaloneAirport, message: 'Please select Airport Code' },
            { value: this.selectedStandaloneVoucher, message: 'Please select Voucher Profile' },
            { value: this.selectedStandaloneReason, message: 'Please select Reason Comment' }

        ]

        for (let validationMessage of validationMessages) {
            if (!validationMessage.value) {
                const toastEvent = new ShowToastEvent({
                    title: 'Warning',
                    message: validationMessage.message,
                });
                this.dispatchEvent(toastEvent);
                return;
            }
        }

        const result = await LightningConfirm.open({
            message: 'ICoupon will be issued to ' + this.paxInfo.length + ' passenger(s) for  ' + this.selectedStandaloneAirport + ' airport '+ '.',
            variant: "default", // headerless
            label: "Confirm Send"
        });
        if (result) {
            this.showIcouponModal = false;
            this.handleStandaloneConfirm();
        } 
    }

    handleStandaloneConfirm() {
        const hideModalEvent = new CustomEvent('hidestandaloneicouponmodal', {
            detail: {
                passengerInfo: this.paxInfo,
                voucherAmount: this.voucherAmount,
                voucherCurrency: this.voucherCurrency,
                airportCode: this.selectedStandaloneAirport,
                reasonId: this.reasonId
            }
        });
        this.dispatchEvent(hideModalEvent);
    }
/* Standalone iCoupon code ends here */

    showToast(title, message) {
    const toastEvent = new ShowToastEvent({
        title,
        message,
    });
    this.dispatchEvent(toastEvent);
    }
    async handleSubmit() {
       
        const isIcouponStation = this.icouponMetadata.some(metadata => metadata['AirportCode__c'] === this.paxInfo[0].thisSegment.stationDeparture);
       
        if (!isIcouponStation) {
            this.showToast('Not a valid Icoupon Station', 'This station is not allowed to send iCoupon voucher.');
            return;
        }

        const validationMessages = [
            { value: this.selectedCurrencyCode, message: 'Please select Currency Code' },
            { value: this.selectedIcouponAmount, message: 'Please select Voucher Amount' },
            { value: this.selectedReasonComment, message: 'Please select Reason Comment' }

        ]

        for (let validationMessage of validationMessages) {
            if (!validationMessage.value) {
                const toastEvent = new ShowToastEvent({
                    title: 'Warning',
                    message: validationMessage.message,
                });
                this.dispatchEvent(toastEvent);
                return;
            }
        }

       var boardingSeq = []; 
       // this.getCommunicationLogsByFlightId(this.paxInfo[0].thisSegment.flightId); 
       for (let pass of this.paxInfo) {
        if( pass.hasThisSegment == true &&
            pass.thisSegment.serviceClass != null && 
            pass.thisSegment.boardingSequenceNumber != null){
                boardingSeq.push(parseInt(pass.thisSegment.boardingSequenceNumber));
        }
  


}
       await  getCommunicationLogsByFlightIdIcoupon({flightId :this.paxInfo[0].thisSegment.flightId,
                                                     boardingSeqNo : boardingSeq
       })
            .then(result => {
                if(result != undefined){
                    console.log('success ' + JSON.stringify(result));
                    this.countExistingComm = result.length;
                }
            })
            .catch(error => {
                console.log('error ' + JSON.stringify(error));
                this.error = error;
            });
        var msg  = '';
       
        if(this.countExistingComm != undefined && this.countExistingComm > 0){
            if(this.countExistingComm == this.paxInfo.length ){
                msg  = 'All selected passenger already received iCoupon, please check Communication Logs for more details.';
                this.stopSuccessAlert = true;
            }
            else{
                msg  = this.countExistingComm +  ' Pax out of ' +this.paxInfo.length +' already received Regular iCoupon, please check Communication Logs for more details. Press Ok to send the iCoupon to remaining passengers.';
      
            }
              const  result= await LightningConfirm.open({
                message: msg ,
                variant: "default", // headerless
                label: "Confirm Send"
            });
            if (result) {
                if(this.stopSuccessAlert == false)
                    {
                        this.handleSuccessAlertClick();
                    }
               
            } else {
                //and false if cancel was clicked
                this.handleErrorAlertClick();
            }
        }

        
        else {
            const result= await LightningConfirm.open({
            message:'This message will be sent to ' + this.paxInfo.length + ' passengers at ' + this.paxInfo[0].thisSegment.stationDeparture + ' with amount ' + this.selectedIcouponAmount + ' ' + this.selectedCurrencyCode + '.',
            variant: "default", // headerless
            label: "Confirm Send"
        });
        if (result) {
            this.handleSuccessAlertClick();
        } else {
            //and false if cancel was clicked
            this.handleErrorAlertClick();
        }
    }
        //Confirm has been closed

        //result is true if OK was clicked
      
        this.includedBoardedPass = false;
    }

    async handleSuccessAlertClick() {
      
        this.handleConfirm();
       // this.showIcouponModal = false;
    }

    icouponMetadataOnLoad() {
        getIcouponMetadata()
            .then(metadata => {
                this.icouponMetadata = metadata;
                console.log('icoupon metadata ' + JSON.stringify(this.icouponMetadata));
            })
            .catch(error => {
                this.error = error;
            });
    }

   

   
}