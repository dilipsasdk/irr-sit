/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description LWC App for IRR Manual Communication.
 */

import { LightningElement, track, api } from 'lwc';
import { convertToCSV } from 'c/c_Json2CsvUtils';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendIcouponManualCommunication from '@salesforce/apex/IRR_CON_ManualCommunication.sendIcouponManualCommunication';
import getFlightPassengerInfos from '@salesforce/apex/IRR_CON_ManualCommunication.getFlightPassengerInfos';
import sendManualCommunication from '@salesforce/apex/IRR_CON_ManualCommunication.sendManualCommunication';
import getManualTemplatesBySendMode from '@salesforce/apex/IRR_CON_ManualCommunication.getManualTemplatesBySendMode';
import sendEmailWithAttachment from '@salesforce/apex/IRR_CON_ManualCommunication.sendEmailWithAttachment';
import getBookingPassengerInfos from '@salesforce/apex/IRR_CON_ManualCommunication.getBookingPassengerInfos';
import getAdvancedFilterPassengerInfos from "@salesforce/apex/IRR_CON_ManualCommunication.getAdvancedFilterPassengerInfos";
import distributionList from '@salesforce/label/c.Distribution_Lists';
import getIcouponMetadata from "@salesforce/apex/IRR_CON_ManualCommunication.getIcouponMetadata";
import sendStanaloneIcouponManualCommunication from '@salesforce/apex/IRR_CON_ManualCommunication.sendStandaloneIcouponManualCommunication';
import * as tableUtil from 'c/c_TableUtil';
import { reduceErrors } from 'c/c_LdsUtils';

import { FLIGHT_COLUMNS, PREVIOUS_FLIGHT_COLUMNS, NEXT_FLIGHT_COLUMNS, BOOKING_COLUMNS, BOOKING_FILTER_COLUMNS } from './passengerTableColumns';
import DeveloperName from '@salesforce/schema/RecordType.DeveloperName';

export default class IRR_ManualCommunication extends LightningElement {

    @track COLUMNS = [];

    @track passengerResult = [];

    @track sortBy = "bookingReference";

    @track sortDirection = "asc";

    @track hasResults;

    @track processedTable = [];
    @track initialRecords;

    @track showRetrieve = true;

    @track loadCount = 0;

    @track errors = [];
    @track criticalError = false;

    @track confirmDetail = {};

    @track showConfirmation = false;

    @track showSuccess = false;

    @track showScheduleSuccess = false;

    @track showRecipientModal = false;

    @track additionalRecipients = [];

    @track additionalHotelRecipients = []

    @track leftPanelTab = "LEFT_FILTER";

    @track templatePreview = "";

    @track isDisabled = false;

    @api emailPicklistOptions = [];

    @track isHotelModel = false;

    @track showIcouponModal = false;

    @track passData;

    @track fileName;

    @track showIcouponButton = true;

    showEmailPicklist = false;

    retrieveParameters = {};

    retrieveParametersWithOldDate = [];

    retrieveParametersWithOldDateCopy = [];

    templatesBySendMode = {};

    sendEmailResult = {};

    selectedRows = [];

    toAddresses = [];;

    filterParameters = {};

    flightHeaders = {
        "thisSegment.flightId": "Flight",
        "bookingReference": "PNR",
        "lastNameSlashFirstName": "Name",
        "phoneNumber": "Phone",
        "emailAddress": "Email",
        "thisSegment.serviceClass": "Service Class",
        "thisSegment.status": "Status",
        "SSR": "SSR",
        "ebLevel": "EB",
        "otherFQTVCarrier": "FQTV"

    };

    connectedCallback() {
        const _ = this.init();
        for (const emailList of distributionList.split(';')) {
            const option = {
                label: emailList,
                value: emailList
            };
            this.emailPicklistOptions = [...this.emailPicklistOptions, option];
        }
        this.icouponMetadataOnLoad();
    }

    async init() {
        try {
            this.templatesBySendMode = await getManualTemplatesBySendMode();
        }
        catch (e) {
            this.handleError(e, true);
        }
    }

    get noPassengersFoundText() {
        return this.passengerResult.length === 0 ?
            'No passengers found, or flight does not exist. Please check Flight ID.' : 'No passengers matching filter';
    }

    get leftPanelTitle() {
        return this.leftPanelTab === "LEFT_FILTER" ? "Apply Filters" : "Preview Template";
    }

    get leftPanelIcon() {
        return this.leftPanelTab === "LEFT_FILTER" ? "utility:filterList" : "utility:preview";
    }

    get tableHeading() {
        if (Object.keys(this.retrieveParameters).length === 0) return "No filters active";
        if (this.retrieveParameters.hasOwnProperty('flightIds') || this.retrieveParameters.hasOwnProperty('bookings')) {
            let params = '';
            if (this.retrieveParameters.hasOwnProperty('bookings')) {
                params = Object.values(this.retrieveParameters).join(" - ");
            }
            else if (this.retrieveParametersWithOldDate.length > 0 && this.retrieveParametersWithOldDate !== undefined) {
                for (let flightData of this.retrieveParametersWithOldDate) {
                    params += `${flightData.flightNumber.padStart(4, '0')}-${flightData.oldDate.replace(/-/g, '')}-${flightData.stationDeparture}-${flightData.stationArrival}` + ',';
                }
                params = params.slice(0, -1);
            }
            return `Results for ${params}`;
        }
        else {
            const params = Object.values(this.retrieveParameters).join(" - ");
            const param = params.split(",");
            const tableHeadings = [];
            for (const p of param) {
                const inputparam = p.split("!");
                const tableHeading = ` From:${inputparam[0]} To:${inputparam[1]}-
                ${inputparam[2].replaceAll(/-/g, '').replaceAll(/:00.000Z/g, '')}-${inputparam[3].replaceAll(/-/g, '').replaceAll(/:00.000Z/g, '')} `;
                tableHeadings.push(tableHeading);
            }
            const tableHeadingContent = tableHeadings.join('||');
            const trimmedTableHeading = tableHeadingContent.replaceAll('From:undefined', 'From:ALL');
            const trimmedTableHeadingFinal = trimmedTableHeading.replaceAll('To:undefined', 'To:ALL');

            return `Results for Bookings => ${trimmedTableHeadingFinal}`;
        }

    }

    get recipientCount() {
        const additionalRecipients = this.additionalRecipients ?
            this.additionalRecipients.filter(r => r.phoneNumber || r.emailAddress).length : 0;
        const recipients = this.selectedRows ? this.selectedRows.length : 0;
        return additionalRecipients + recipients;
    }

    handleGlobalKeyUp(event) {
        if (event.key === 'Escape') {
            if (this.errors && this.errors.length > 0 && !this.criticalError) this.clearErrors();
            else if (this.showConfirmation) this.handleHideConfirmEvent();
            else if (this.showRecipientModal) this.template.querySelector('c-irr_-recipient-modal').handleCancel();
            else if (this.showSuccess) this.handleHideSuccessEvent();
            else if (this.showScheduleSuccess) this.handleHideScheduleEvent();
            else if (!this.showRetrieve) this.handleResetEvent();
        }
    }

    handleEmailChange(event) {
        this.toAddresses = event.detail.value;
    }

    handleTabSwitch(event) {
        this.leftPanelTab = event.target.value;
    }

    handleLoad(finished) {
        if (finished && this.loadCount === 0) return;
        this.loadCount += finished ? -1 : 1;
    }

    handleError(error, critical) {
        this.loadCount = 0;
        if (critical) this.criticalError = critical;
        this.errors = reduceErrors(error);
    }

    clearErrors(_) {
        this.errors = [];
    }

    handleTableSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    handleHideRecipientModal() {
        this.showRecipientModal = false;
    }

    handleShowRecipientModal() {
        this.showRecipientModal = true;
    }

    handleUpdateAdditionalRecipients(event) {
        this.additionalRecipients = event.detail;
        this.showRecipientModal = false;
    }

    handleFilterApplyEvent(event) {
        this.filterParameters = event.detail;
        this.COLUMNS = [];
        if (this.filterParameters.hasNextSegment) {
            this.COLUMNS = NEXT_FLIGHT_COLUMNS;
        }
        else if (this.filterParameters.hasPrevSegment) {
            this.COLUMNS = PREVIOUS_FLIGHT_COLUMNS;
        }
        else if (!this.filterParameters.hasNextSegment && !this.filterParameters.hasPrevSegment) {
            this.COLUMNS = FLIGHT_COLUMNS;
        }
        else if (this.retrieveParameters.flightIds) {
            this.COLUMNS = FLIGHT_COLUMNS;
        }

        this.processTable();
    }

    handleHideSuccessEvent() {
        this.showSuccess = false;
        this.emailPicklistOptions = '';
    }

    handleHideScheduleEvent() {
        this.showScheduleSuccess = false;
    }

    processTable() {
        for (let objOldDate of this.retrieveParametersWithOldDate) {
            if (objOldDate.flightNumber !== undefined && objOldDate.flightNumber !== null && !objOldDate.flightNumber.includes('SK')) {
                objOldDate.flightNumber = 'SK' + objOldDate.flightNumber.padStart(4, '0')
            }

        }
        let filteredList = tableUtil.filterData(this.passengerResult, this.filterParameters);
        tableUtil.sortData(filteredList, this.sortBy, this.sortDirection);
        this.hasResults = filteredList.length > 0;
        for (let passengerInfo of filteredList) {
            let currentflightNumber = passengerInfo['thisSegment.flightNumber'];
            let oldDateWithFlight = this.retrieveParametersWithOldDate.find((opt => opt.flightNumber === currentflightNumber));
            console.log(JSON.stringify(oldDateWithFlight));
            let currentFlightId = passengerInfo['thisSegment.flightId'];
            let localDate;
            if (oldDateWithFlight !== undefined && oldDateWithFlight.oldDate !== null && oldDateWithFlight.oldDate !== '') {
                localDate = oldDateWithFlight.oldDate.substring(5, 7) + oldDateWithFlight.oldDate.substring(8, 10);
            }

            if (currentFlightId !== null && currentFlightId !== '' && currentFlightId !== undefined && localDate !== undefined && localDate !== '') {
                passengerInfo['thisSegment.flightId'] = currentFlightId.substring(0, 11) + localDate + currentFlightId.substring(15, 25);
            }
             //Removing group booking passengers for manual UI only
            filteredList.forEach(function(obj) {
                if(obj.codsId === 'deletePass'){
                  filteredList.splice(filteredList.findIndex(a => a.codsId === 'deletePass') , 1)
                }
               
            });
            this.processedTable = filteredList;
            this.initialRecords = filteredList;


        }
    }
    handleTableSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.processTable();
    }

    handleHideConfirmEvent(_) {
        this.showConfirmation = false;
    }

    handleTemplateChange(event) {
        const { template } = event.detail;
        this.templatePreview = template.templatePreview;
        if (this.leftPanelTab !== "LEFT_PREVIEW") this.leftPanelTab = "LEFT_PREVIEW";
    }

    handleSendEvent(event) {
        if (this.recipientCount === 0) {
            const toastEvent = new ShowToastEvent({
                title: 'No Recipients',
                message: 'Please select at least one recipient in order to continue.',
            });
            this.dispatchEvent(toastEvent);
            return;
        }
        this.confirmDetail = event.detail;
        this.showConfirmation = true;
    }

  async handleSendConfirmEvent(event) {
    try {
      this.showConfirmation = false;
      this.handleLoad(false);
      const { sendTime, sendSMS, sendEmail } = event.detail;
      const {
        parameters,
        sendMode,
        manualTemplate,
        fileUploaded,
        uploadedFileData
      } = this.confirmDetail;
      const passengerInfos = this.selectedRows.map((row) =>
        tableUtil.unFlatten(row)
      );
      passengerInfos.push(
        ...this.additionalRecipients.map((rec) => {
          return {
            thisSegment: { flightId: this.retrieveParameters.flightIds },
            lastNameSlashFirstName: "ADDITIONAL/RECIPIENT",
            hasPhoneNumber: !!rec.phoneNumber,
            hasEmailAddress: !!rec.emailAddress,
            phoneNumber: rec.phoneNumber,
            emailAddress: rec.emailAddress
          };
        })
      );
      const payload = {
        responseMessage: manualTemplate.responseTemplate,
        passengerInfos: passengerInfos,
        sendSMSMessages: sendSMS,
        sendEmailMessages: sendEmail,
        sendMessageTime: sendTime,
        emailTemplate: manualTemplate.emailTemplate,
        smsTemplate: manualTemplate.smsTemplate
      };
      switch (sendMode) {
        case "CUSTOM":
          payload.customInfo = parameters;
          break;
        case "DELAY":
          payload.delayInfo = parameters;
          break;
        case "NEW_INFO":
          payload.newInfo = parameters;
          break;
        case "CANCEL":
          payload.cancelInfo = parameters;
          break;
        case "CHECKIN":
          payload.checkinInfo = parameters;
          break;
        case "SCHEDULED_CHANGE":
          payload.scheduledChangeInfo = parameters;
          break;
        case "REBOOK":
          break;
        case "LOUNGE_VOUCHER":
          break;
        case "TEMPLATE":
          break;
        default:
          return;
      }
      if (sendMode != "CUSTOM") {
        await sendManualCommunication({ manualRequest: payload });
      } else {
        if (sendSMS && sendEmail) {
          if (fileUploaded) {
            //sf emailsent
            await sendEmailWithAttachment({
              fileName: uploadedFileData.fileName,
              fileType: uploadedFileData.fileType,
              fileBase64Data: uploadedFileData.base64Data,
              manualRequest: payload
            });
            payload.sendEmailMessages = false;
          } else {
            payload.sendSMSMessages = false;
            await sendManualCommunication({ manualRequest: payload });
            payload.sendEmailMessages = false;
          }
          payload.sendSMSMessages = true;
          payload.customInfo = {
            ...parameters,
            content: parameters.smscontent
          };
          await sendManualCommunication({ manualRequest: payload });
        } else if (sendSMS) {
          payload.customInfo = {
            ...parameters,
            content: parameters.smscontent
          };
          await sendManualCommunication({ manualRequest: payload });
        } else {
          if (fileUploaded) {
            await sendEmailWithAttachment({
              fileName: uploadedFileData.fileName,
              fileType: uploadedFileData.fileType,
              fileBase64Data: uploadedFileData.base64Data,
              manualRequest: payload
            });
          } else {
            await sendManualCommunication({ manualRequest: payload });
          }
        }
      }

      this.handleLoad(true);

      if (sendTime !== null) {
        this.showScheduleSuccess = true;
      } else {
        this.showSuccess = true;
      }
    } catch (e) {
      this.handleError(e);
    }
  }

    handleResetEvent(_) {
        this.flightId = '';
        this.retrieveParameters = {};
        this.processedTable = [];
        this.initialRecords = [];
        this.passengerResult = [];
        this.additionalRecipients = [];
        this.template.querySelector('c-irr_-recipient-modal').reset();
        this.leftPanelTab = "LEFT_FILTER";
        this.showRetrieve = true;
        this.showSuccess = false;
        this.showScheduleSuccess = false;
        this.emailPicklistOptions = '';
    }

    async handleRetrieveEvent(event) {
        try {
            this.handleLoad(false);
            const { parameters, retrievalMode, allFlightData } = event.detail;
            if (retrievalMode !== 'BYPASS') {
                this.retrieveParametersWithOldDate = allFlightData;
            }

            let result;
            let eventParameters;
            switch (retrievalMode) {
                case "FLIGHT_REFERENCE":
                    this.showIcouponButton = true;
                    this.COLUMNS = FLIGHT_COLUMNS;
                    eventParameters = { flightIds: parameters.flightIds };
                    result = await getFlightPassengerInfos(eventParameters);
                    this.filterParameters = { 'thisSegment.statusCode': ['HK','KL', 'TK', 'HL' ,'SA'] };
                    break;
                case "BOOKING_REFERENCE":
                    this.showIcouponButton = false;
                    this.COLUMNS = BOOKING_COLUMNS;
                    eventParameters = { bookings: parameters.bookingId };
                    result = await getBookingPassengerInfos(eventParameters);
                    this.filterParameters = {};
                    break;
                case "BOOKING_FILTER":
                    this.COLUMNS = BOOKING_FILTER_COLUMNS;
                    eventParameters = { bookingIds: parameters.bookingIds };
                    result = await getAdvancedFilterPassengerInfos(eventParameters);
                    this.filterParameters = { 'thisSegment.status': ['Confirmed', 'SpaceAvailable', 'Waitlisted'] };
                    break;
                case "BYPASS":
                    this.COLUMNS = [];
                    this.filterParameters = {};
                    break;
                default:
                    return;
            }
            if (eventParameters) this.retrieveParameters = eventParameters;
            if (result) this.passengerResult = result.map(item => tableUtil.flatten(item));
            if (result) this.passengerResultunflatten = result;
            this.processTable();
            //Focus container div to capture keyboard events
            this.template.querySelector('div[focusable=""]').focus();
            this.showRetrieve = false;
            this.handleLoad(true);
        }
        catch (e) {
            this.handleError(e);
        }
    }

    handleFileSend() {
        const passengerInfos = this.selectedRows.map(row => tableUtil.flatten(row));
        const params = Object.values(this.retrieveParameters).join(" - ");
        const param = params.split('-');
        const [flight, date, departureStation] = param;
        this.fileName = `${flight}_${departureStation}_${date}`;
        if (this.selectedRows.length > 0) {
            this.isHotelModel = true
            const csvData = convertToCSV(passengerInfos, this.flightHeaders);
            if (csvData == null) return;
            this.paxData = csvData;
            this.passengerCount = this.selectedRows.length;
        } else {
            const toastEvent = new ShowToastEvent({
                title: 'No Recipients Selected',
                message: 'Please select at least one recipient in order to email the Attachment.',
            });
            this.dispatchEvent(toastEvent);
            return;
        }


    }
    hideHotelModel(event) {
        this.isHotelModel = event.detail;
    }
    handleShowIcouponModal() {
        const selectedPassengers = this.selectedRows.map(row => tableUtil.flatten(row));
        //console.log('selectedPassengers' + JSON.stringify(selectedPassengers));
        let firstPassenger = '';
        let stationDeparture = '';
        let serviceClass = '';
        if (this.selectedRows.length > 0) {
            firstPassenger = selectedPassengers[0];
            stationDeparture = firstPassenger['thisSegment.stationDeparture'];
            serviceClass = firstPassenger['thisSegment.serviceClass'];



        }
        const hasBoardingSequenceNumber = selectedPassengers.every(passenger => {
            const boardingSequenceNumber = passenger['thisSegment.boardingSequenceNumber'];
            return boardingSequenceNumber != null && boardingSequenceNumber !== '';
        });



        const isIcouponStation = this.icouponMetadata.some(metadata => metadata['AirportCode__c'] === stationDeparture);

        const numSelectedRows = this.selectedRows.length;

        if (numSelectedRows === 0) {
            this.showToast('No Recipients Selected', 'Please select at least one recipient in order to send voucher email.');
            return;
        }

        /**if (!isIcouponStation) {
            this.showToast('Not a valid Icoupon Station', 'This station is not allowed to send iCoupon voucher.');
            return;
        }*/
        //commented this condition because standalone iCoupon can be sent without boarding sequence number
        /*if (!hasBoardingSequenceNumber) {
            this.showToast('No Boarding Sequence Number ', 'Passenger does not have a boarding sequence number.');
            return;
        }*/

        const hasDifferentServiceClass = selectedPassengers.some(passenger => passenger['thisSegment.serviceClass'] !== serviceClass);

        if (hasDifferentServiceClass) {
            this.showToast('No Filter selected ', 'Please select the service class filter first.');
            return;
        }

        this.showIcouponModal = true;

        const unflattenedSelectedPassengers = this.selectedRows.map(row => tableUtil.unFlatten(row));
        this.template.querySelector('c-irr_-icoupon').icouponPassengerData(unflattenedSelectedPassengers, serviceClass);

    }
    handleHideIcouponModal(event) {
        this.showIcouponModal = false;
        if(event.detail.currencyCode !==undefined && event.detail.currencyCode !== ''){
            this.handleLoad(false);
            sendIcouponManualCommunication({
                passengerInfo: event.detail.passengerInfo,
                voucherAmount: parseInt(event.detail.voucherAmount),
                currencyCode: event.detail.currencyCode,
                reasonComment: event.detail.reasonComment,
                isIncludedBoarded: event.detail.isIncludedBoarded
            })
    
                .then(result => {
                    this.handleLoad(true);
                    this.showToast('Success','iCoupon email has been sent succesfully.');
                    
                }).catch(error => {
                    console.log(JSON.stringify(error))
                    this.showToast('Error',error.body.stackTrace);
                });
        
    
       }
        
       
    }

    handleHideStandaloneIcouponModal(event) {
        this.showIcouponModal = false;
        if(event.detail.airportCode !==undefined && event.detail.airportCode !== ''){
            this.handleLoad(false);
            sendStanaloneIcouponManualCommunication({
            passengerInfo: event.detail.passengerInfo,
            voucherAmount: event.detail.voucherAmount,
            voucherCurrency: event.detail.voucherCurrency,
            airportCode: event.detail.airportCode,
            reasonId: event.detail.reasonId
        })

            .then(result => {
                this.handleLoad(true);
                const toastEvent = new ShowToastEvent({
                    title: 'Success',
                    message: 'iCoupon email/sms sent successfully',
                });
                this.dispatchEvent(toastEvent);
               
            }).catch(error => {
                this.handleLoad(true);
                this.error = error;
                const toastEvent = new ShowToastEvent({
                    title: 'Error',
                    message: 'Error sending iCoupon email/sms. Please try again.',
                });
                this.dispatchEvent(toastEvent);
            });
        }
    }

    icouponMetadataOnLoad() {
        getIcouponMetadata()
            .then(metadata => {
                this.icouponMetadata = metadata;
            })
            .catch(error => {
                this.error = error;
            });
    }
    showToast(title, message) {
        const toastEvent = new ShowToastEvent({
            title,
            message,
        });
        this.dispatchEvent(toastEvent);
    }
    @track dataTemp;
    handleSearch(event) {
       const searchKey = event.target.value.toLowerCase();
       if (searchKey) {
            this.processedTable = this.initialRecords;
            if (this.processedTable) {
                let searchRecords = [];
                for (let record of this.processedTable) {
                    if (record['nextSegment.flightId']?.toLowerCase().includes(searchKey) ||
                        record['prevSegment.flightId']?.toLowerCase().includes(searchKey) ||
                        record['thisSegment.flightId'].toLowerCase().includes(searchKey) ||
                               record['bookingReference'].toLowerCase().includes(searchKey) ||
                               (record['hasEmailAddress']  && record['emailAddress'].toLowerCase().includes(searchKey)) ||
                               record['firstName'].toLowerCase().includes(searchKey) ||
                               (record['hasPhoneNumber'] && record['phoneNumber'].toLowerCase().includes(searchKey)) ||
                               record['SSR'].toLowerCase().includes(searchKey) ||
                               record['thisSegment.statusCode'].toLowerCase().includes(searchKey) ||
                               (record['ebLevel']&& record['ebLevel'].toLowerCase().includes(searchKey))  ||
                               record['lastName'].toLowerCase().includes(searchKey) ) {
                               searchRecords.push(record);
                        
                            }
                }
                this.processedTable = searchRecords;
                //check if user are entering 5 digit flight id and then adding zero just after SK
               if(searchKey !== undefined && searchKey.includes("sk") && searchKey.length <= 5 &&  searchKey.length > 2 && searchRecords.length == 0){
                    var flightNumber  =  searchKey.split("sk")[1];
                    var flightId = '';
                    console.log('flightNumber ' + flightNumber);
                    if(flightNumber.length == 1){
                        flightId = 'sk' + '000' + flightNumber;
                        console.log('flightId ' + flightId);
                        
                    }
                    else if(flightNumber.length == 2){
                        flightId = 'sk' + '00' + flightNumber;
                    }
                    else if(flightNumber.length == 3){
                        flightId = 'sk' + '0' + flightNumber;
                    }
                    this.handleSearch2(flightId);
                }
                
            }
        } else {
            this.processedTable = this.initialRecords;
        }
    }

    
handleSearch2(searchKey) {
    if (searchKey) {
        this.processedTable = this.initialRecords;
        if (this.processedTable) {
            let searchRecords = [];
             for (let record of this.processedTable) {
                 if (record['nextSegment.flightId']?.toLowerCase().includes(searchKey) ||
                     record['prevSegment.flightId']?.toLowerCase().includes(searchKey) ||
                     record['thisSegment.flightId'].toLowerCase().includes(searchKey) ||
                               record['bookingReference'].toLowerCase().includes(searchKey) ||
                               (record['hasEmailAddress']  && record['emailAddress'].toLowerCase().includes(searchKey)) ||
                               record['firstName'].toLowerCase().includes(searchKey) ||
                               (record['hasPhoneNumber'] && record['phoneNumber'].toLowerCase().includes(searchKey)) ||
                               record['SSR'].toLowerCase().includes(searchKey) ||
                               record['thisSegment.statusCode'].toLowerCase().includes(searchKey) ||
                               (record['ebLevel']&& record['ebLevel'].toLowerCase().includes(searchKey))  ||
                               record['lastName'].toLowerCase().includes(searchKey) ) {
                                searchRecords.push(record);
                            }
            }
            this.processedTable = searchRecords;
          }
    } else {
        this.processedTable = this.initialRecords;
    }
}
}