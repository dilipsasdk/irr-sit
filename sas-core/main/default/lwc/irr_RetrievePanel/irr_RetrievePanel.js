/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description Passenger retrieve panel for the Manual Communication app.
 */

import TimeSegment__c from '@salesforce/schema/SBS_ScheduledBatchComponent__mdt.TimeSegment__c';
import {LightningElement, track} from 'lwc';
import getTimezoneByAirport from "@salesforce/apex/IRR_CON_ManualCommunication.getTimezoneByAirport";
const DATE_TODAY = new Date().toJSON().slice(0,10);

export default class irr_RetrievePanel extends LightningElement {

    retrievalMode = "FLIGHT_REFERENCE";

    @track retrieveParameters = {};

    @track flights = [];

    @track flightsCopy = [];

    @track bookings = [];
    @track timeZoneAirport = [];
    @track departureAirport ;
    momentjsInitialized = false;
    flightKeyTracker = 0;

    bookingsKeyTracker = 0;

    showBookingFiltersTab = false;

    showFlightInputParams =true;

    firstTime = true;

    isTimeZoneVisible = false;
    
    connectedCallback() {
        this.onLoad(); 
        //Initialize component with first flight
        if(this.firstTime) {
            this.handleFlightAdd();
        }  
      


    }

    handleKeyPress(event) {
        if (event.key === 'Enter') {
            this.handleRetrieve();
        }
    }

    handleAdvanceFilterChange(event) {
        if (event.target.checked){
            this.showBookingFiltersTab = true;
            this.showFlightInputParams = false;
            this.retrievalMode = "BOOKING_FILTER";
            this.retrieveParameters = {};
            this.handleBookingAdd();
        }else {
            this.showFlightInputParams = true;
            this.showBookingFiltersTab = false;
            this.bookings = [];
        }
        
    }

    handleParameterChange(event) {
        //Text parameters should automatically be upper case
        this.retrieveParameters[event.target.name] = event.target.type === "text" ?
            event.target.value.toUpperCase() : event.target.value;

        this.retrievalMode = event.currentTarget.dataset.tabGroup;
    }

    handleFlightChange(event) {
        const { name, value, dataset: { flightIdx } } = event.target;
        let isStationDepartureFind = false;
        if(event.target.name == "stationDeparture"){
            isStationDepartureFind = this.timeZoneAirport.some(opt => opt.IRR_Airport_Code__c === value.toUpperCase());
            this.departureAirport = value.toUpperCase();
        }
        if(event.target.name == "stationDeparture" &&  isStationDepartureFind){
        this.flights[flightIdx].isTimeZoneVisible = true;
        let timzoneMetadata = this.timeZoneAirport.find(opt => opt.IRR_Airport_Code__c === this.departureAirport);
        this.flights[flightIdx].timeZone = timzoneMetadata.IRR_Time_Zone__c;
        }
         else if(event.target.name == "stationDeparture" && !isStationDepartureFind){
            this.flights[flightIdx].isTimeZoneVisible = false;
         };
         if(event.target.name == "departureDate" && !String(value).includes('.000Z')){
            this.flightsCopy[flightIdx].oldDate = value.substring(0, 10);
         }
         if(event.target.name == "departureDate"  && String(value).includes('.000Z')){
                   let zone;
                   console.log('input date  ' + value);
                   this.flightsCopy[flightIdx][name] = value.substring(0, 10);
                     
         }
         else if(event.target.type !== "text" && !String(value).includes('.000Z')){
                     console.log('value'  + value)
                     this.flights[flightIdx][name] = value;
                     this.flightsCopy[flightIdx][name] = value;
                     this.flightsCopy[flightIdx].oldDate = value.substring(0, 10);
         }
         else if(event.target.type === "text") {
                     this.flights[flightIdx][name] = value.toUpperCase();
                     this.flightsCopy[flightIdx][name] = value.toUpperCase();
                   
            }
           
        var inp = this.template.querySelectorAll("lightning-input");
        inp.forEach(function(element){
            if(element.name=="departureDate") {
             this.DATE_SELECTED=element.value.substring(0, 10) ;
            }
        },this);
    }

    handleBookingsFilter(event) {
        const { name, value, dataset: { bookingIdx } } = event.target;
        this.bookings[bookingIdx][name] = event.target.type === "text" ? value.toUpperCase() : value;
        this.retrievalMode = event.currentTarget.dataset.tabGroup;

    }

    handleFlightAdd() {
        const flightKey = ++this.flightKeyTracker;
            if(this.firstTime) {
                 this.flights.push( { key: `flight-${flightKey}`, departureDate: DATE_TODAY ,isTimeZoneVisible :false,oldDate :DATE_TODAY } );
                 this.flightsCopy.push( { key: `flight-${flightKey}`, departureDate: DATE_TODAY ,oldDate :DATE_TODAY } );
            } else {
            // Requirement : copy the previous date selected if user adds more flights
                this.flights.push( { key: `flight-${flightKey}`, departureDate: this.DATE_SELECTED, isTimeZoneVisible: false,oldDate :this.DATE_SELECTED  } );
                this.flightsCopy.push( { key: `flight-${flightKey}`, departureDate: this.DATE_SELECTED,oldDate :this.DATE_SELECTED } );
                 
            }
            this.firstTime = false;
    }

    handleBookingAdd(){
        const bookingsKey = ++this.bookingsKeyTracker;
        this.bookings.push( { key: `bookings-${bookingsKey}` } );

    }

    handleFlightRemove(event) {
        const index = parseInt(event.currentTarget.dataset.flightIdx);
        this.flights.splice(index, 1);
        this.flightsCopy.splice(index, 1);
        this.DATE_SELECTED = DATE_TODAY;
    }
    handleBookingsRemove(event) {
        const index = parseInt(event.currentTarget.dataset.bookingIdx);
        this.bookings.splice(index, 1);

    }

    handleTabSwitch(event) {
        this.retrievalMode = event.target.value;
        this.showBookingFiltersTab = false;
        this.showFlightInputParams = true;
            let advanceFilterCheckbox = this.template.querySelector('[data-advance-filter = "checkbox"]');
            // when you query checkbox right after you switched the tab, the element
            // is stil not available in DOM at that time hence put a timeout 
            if (advanceFilterCheckbox != null) {
                setTimeout(()=>this.template.querySelector('[data-advance-filter = "checkbox"]').checked=false);
            }
            this.bookings = [];
    }
    validateFields() {
        return [...this.template.querySelectorAll(`lightning-input[data-tab-group="${this.retrievalMode}"]`)]
            .reduce((previousValue, cmp) => cmp.reportValidity() && previousValue, true);
    }

    handleRetrieve() {
        if (!this.validateFields()) return; 
        if (this.retrievalMode === "FLIGHT_REFERENCE") this.constructFlightIds();
        if (this.retrievalMode === "BOOKING_FILTER") this.constructBookingIds();
        const retrievalEvent = new CustomEvent('retrieve' , {
            detail: { parameters: this.retrieveParameters, retrievalMode: this.retrievalMode, allFlightData : this.flightsCopy}
        });
        this.dispatchEvent(retrievalEvent);
    }

    constructFlightIds() {
            
    
        this.retrieveParameters.flightIds = this.flightsCopy.map(flight => {
            const { flightNumber, departureDate, stationDeparture, stationArrival } = flight;
            return `SK${flightNumber.padStart(4, '0')}-${departureDate.replace(/-/g,'')}-${stationDeparture}-${stationArrival}`;
        }).join(',');
    }
    constructBookingIds(){
        this.retrieveParameters.bookingIds = this.bookings.map(booking => {
            const { departureStation, arrivalStation, departureDate, arrivalDate } = booking;
            return `${departureStation}!${arrivalStation}!${departureDate}!${arrivalDate}`;
        }).join(',');
    }

    handleBypass() {
        const retrievalEvent = new CustomEvent('retrieve' , {
            detail: { retrievalMode: 'BYPASS' }
        });
        this.dispatchEvent(retrievalEvent);
    }

    onLoad() {
        getTimezoneByAirport()
            .then(metadata =>{
               this.timeZoneAirport = metadata;
               //console.log('time zone metadata' + JSON.stringify(this.timeZoneAirport));
            })
            .catch(error =>{
                this.error = error;
            });
    }
}