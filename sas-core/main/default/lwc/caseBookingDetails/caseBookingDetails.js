import { LightningElement, track, api, wire } from "lwc";
import addBookingToCaseApex from "@salesforce/apex/CustomerCardController.addBookingToCase";
import getBookingsForCaseApex from "@salesforce/apex/CustomerCardController.getBookingsForCase";
import removeBookingFromCaseApex from "@salesforce/apex/CustomerCardController.removeBookingFromCaseIdentifier";
import refetchBookingDataApex from "@salesforce/apex/CustomerCardController.refetchBookingData";
import ChatTranscript_CASEID_FIELD from "@salesforce/schema/LiveChatTranscript.CaseId";
import { refreshApex } from "@salesforce/apex";
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import { NavigationMixin } from "lightning/navigation";
import { formattedDateString, minutesToHoursAndMinutes } from "c/utilDate";
import { toCapitalCase } from "c/utilString";
import Case_RECORDID_FIELD from "@salesforce/schema/Case.Id"
import CASE_PNR_FIELD from '@salesforce/schema/Case.FCS_PNR__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseBookingDetails extends NavigationMixin(LightningElement) {
  @api objectApiName;
  @api recordId;

  ENTRIES_TO_DISPLAY = 3;
  PAST_BOOKINGS_TO_DISPLAY = 5;
  UPCOMING_BOOKINGS_TO_DISPLAY = 5;

  bookings = [];
  pastBookings = [];
  upcomingBookings = [];

  caseId = undefined;
  hasUpcomingBookings = false;
  hasPastBookings = false;
  pastBookingCount = 0;
  upcomingBookingCount = 0;

  displayedAllPastBookings = false;
  displayedAllUpcomingBookings = false;

  recordTypeName;
  addPNRVisible = false;

  get shownUpcomingBookingCount() {
    return this.UPCOMING_BOOKINGS_TO_DISPLAY >= this.upcomingBookings.length ? `Showing all bookings` : `Showing ${this.UPCOMING_BOOKINGS_TO_DISPLAY} out of ${this.upcomingBookings.length} bookings`;
  }

  get shownPastBookingCount() {
    return this.PAST_BOOKINGS_TO_DISPLAY >= this.pastBookings.length ? `Showing all bookings` : `Showing ${this.PAST_BOOKINGS_TO_DISPLAY} out of ${this.pastBookings.length} bookings`;
  }

  get visibleUpcomingBookings() {
    return this.displayedAllUpcomingBookings ? this.upcomingBookings : this.upcomingBookings.slice(0, Math.min(this.UPCOMING_BOOKINGS_TO_DISPLAY, this.upcomingBookings.length));
  }

  get visiblePastBookings() {
    if (this.pastBookings) {
      return this.displayedAllPastBookings ? this.pastBookings: this.pastBookings.slice(0, Math.min(this.PAST_BOOKINGS_TO_DISPLAY, this.pastBookings.length));
    }
  }

  get visiblePastBookingCount() {
    return `Past bookings (${this.pastBookings.length})`;
  }

  get visibleUpcomingBookingCount() {
    return `Upcoming bookings (${this.upcomingBookings.length})`;
  }

  wiredRecordReference;
  wiredBookingsReference;

  @track showSpinner = false;
  @track noSearchResult = false;
  @track error = false;
  @track searchValue = "";
  displayAddAnotherBookingForm = false;

  @wire(getRecord, {
    recordId: "$recordId",
    optionalFields: [
      // Use optional fields because object type varies
      ChatTranscript_CASEID_FIELD
    ]
  })
  wiredRecord(value) {
    this.wiredRecordReference = value;
    const { data, error } = value;
    if (!error && data) {
      this.recordTypeName = data.recordTypeInfo.name;
      if (this.recordTypeName === 'Channel' || this.recordTypeName === 'Call' || this.recordTypeName === 'Chat' || this.recordTypeName === 'Internal/Backoffice') {
        this.addPNRVisible = true;
      }
      if (this.objectApiName === "LiveChatTranscript") {
        this.caseId = data.fields.CaseId.value;
      } else {
        this.caseId = this.recordId;
      }
    }
  }

  get duplicateBookings() {
    if (this.bookings == undefined) {
      return [];
    }
    const bookingReferenceToCount = this.bookings.reduce((acc, curr) => {
      const count = acc.get(curr.bookingReference) || 0;
      acc.set(curr.bookingReference, count + 1);
      return acc;
    }, new Map());

    return this.bookings.filter(
      (b) => bookingReferenceToCount.get(b.bookingReference) > 1
    );
  }

  get hasDuplicates() {
    return this.duplicateBookings.length > 0;
  }

  @wire(getBookingsForCaseApex, { caseId: "$caseId" })
  wiredBookings(value) {
    this.wiredBookingsReference = value;
    const { data, error } = value;

    if (error) {
      this.error = error;
      this.bookings = undefined;  
      return;
    }
    if (data != undefined && data.length > 0) {
      this.bookings = data.map((b) => ({
        ...b,
        displayDetails: {
          showAllPassengers: b.passengers.length <= this.ENTRIES_TO_DISPLAY,
          showAllFlights: b.flights.length <= this.ENTRIES_TO_DISPLAY
        },
        travelOfficeId:
          b.createdAtTravelOfficeId && b.createdAtTravelOfficeId.length > 0
            ? `/${b.createdAtTravelOfficeId}`
            : "",
        trips: this.populateTrips(b.flights),
        passengers: this.populatePassengers(b.passengers)
      }));
    } else {
      this.bookings = undefined;
    }
    if (this.bookings) {
      this.bookings = this.bookings.map((booking) => {
        const TODAY = new Date();
        
        const scheduledDate = new Date(
          booking.flights[0].scheduledDepartureTime
        );

        const caseCount = booking.relatedCases
          ? booking.relatedCases.filter((c) => c.Id !== this.caseId).length
          : 0;

        const logCount = booking.relatedCommunicationLogs
          ? booking.relatedCommunicationLogs.length
          : 0;

        function getAirportListForBooking(booking) {
          if (!booking.flights || booking.flights.length < 1) {
            return "";
          }
          return `${booking.flights[0].departureAirport}-${booking.flights[0].arrivalAirport}`;
        }
          
        return {
          ...booking,
          upcomingBooking: 
            scheduledDate >= TODAY ? true : false,
          relatedCases: booking.relatedCases.filter(
            (c) => c.Id !== this.caseId
          ),
          displayDetails: {
            ...booking.displayDetails,
            caseTabTitle: `Related cases (${caseCount})`,
            communicationLogsTabTitle: `Related communication logs (${logCount})`,
            noCases: caseCount === 0,
            passengersVisible: `${
              booking.displayDetails.showAllPassengers
                ? booking.passengers.length
                : this.ENTRIES_TO_DISPLAY
            } of ${booking.passengers.length}`,
            flightsVisible: `${
              booking.displayDetails.showAllFlights
                ? booking.trips.reduce(
                    (acc, curr) => acc + curr.flights.length,
                    0
                  )
                : Math.min(
                    this.ENTRIES_TO_DISPLAY,
                    booking.trips[0].flights.length
                  )
            } of ${booking.trips.reduce(
              (acc, curr) => acc + curr.flights.length,
              0
            )}`
          },
          visiblePassengers: booking.displayDetails.showAllPassengers
            ? booking.passengers
            : booking.passengers.slice(
                0,
                Math.min(booking.passengers.length, this.ENTRIES_TO_DISPLAY)
              ),
          trips: booking.displayDetails.showAllFlights
            ? booking.trips
            : [
                // If we display only some flights, display only flights from the first trip
                {
                  ...booking.trips[0],
                  flights: booking.trips[0].flights.slice(
                    0,
                    Math.min(
                      booking.trips[0].flights.length,
                      this.ENTRIES_TO_DISPLAY
                    )
                  )
                }
              ],
          accordionTitle: `${formattedDateString(
            booking.flights[0].scheduledDepartureTimeLocal,
            "date"
          )} ${getAirportListForBooking(booking)} ${booking.bookingReference}`
        };
      }) 
    }
    if (this.bookings) {
      this.bookingFiltering(this.bookings);
    }
  }

  populatePassengers(passengers) {
    return passengers.map((p) => ({
      ...p,
      bags: p.bags ? p.bags : ["-"],
      email: p.email || "-",
      euroBonusNumber:
        p.euroBonusNumber && p.euroBonusNumber.length > 0
          ? p.euroBonusNumber
          : "-",
      name: `${toCapitalCase(p.firstName)} ${toCapitalCase(p.lastName)}`,
      phone: p.phone || "-",
      seats: p.seats ? p.seats : ["-"],
      ssrs: p.specialServiceRequests,
      ticketNumbers:
        p.ticketNumbers && p.ticketNumbers.length > 0
          ? p.ticketNumbers.join(", ")
          : "-"
    }))
  }
  
  populateTrips(flights) {
    return Object.entries(
      flights
        .map((f) => {
          const delayedOrCancelled =
            f.arrivalStatus === "delayed" ||
            f.departureStatus === "delayed" ||
            f.departureStatus === "cancelled";
  
          return {
            ...f,
            arrivalDelayed: f.arrivalStatus === "delayed",
            arrivalDelayedMinutes: minutesToHoursAndMinutes(
              f.arrivalDelayedMinutes
            ),
            arrivalTimeClassName:
              f.arrivalStatus === "delayed" || f.arrivalStatus === "cancelled"
                ? "delayed-time"
                : "",
            arrivalGate: f.arrivalGate || "-",
            arrivalTerminal: f.arrivalTerminal || "-",
            bookingClass: f.bookingClass || "-",
            cancelled: f.departureStatus === "cancelled",
            departureDelayed: f.departureStatus === "delayed",
            departureDelayedMinutes: minutesToHoursAndMinutes(
              f.departureDelayedMinutes
            ),
            departureTimeClassName:
              f.departureStatus === "delayed" || f.departureStatus === "cancelled"
                ? "delayed-time"
                : "",
            departureGate: f.departureGate || "-",
            departureTerminal: f.departureTerminal || "-",
            estimatedArrivalTimeLocal: formattedDateString(
              f.estimatedArrivalTimeLocal,
              "time"
            ),
            estimatedDepartureTimeLocal: formattedDateString(
              f.estimatedDepartureTimeLocal,
              "time"
            ),
            fareBasis: f.fareBasis || "-",
            bulletClassName: delayedOrCancelled
              ? "flight-bullet-delayed"
              : "flight-bullet-on-time",
            scheduledArrivalTimeLocal: formattedDateString(
              f.scheduledArrivalTimeLocal,
              "time"
            ),
            scheduledDepartureDateLocal: formattedDateString(
              f.scheduledDepartureTimeLocal,
              "date"
            ),
            scheduledDepartureTimeLocal: formattedDateString(
              f.scheduledDepartureTimeLocal,
              "time"
            ),
            segmentStatusCode: f.segmentStatusCode || "-",
            serviceClass: f.serviceClass || "-"
          };
        })
        .reduce(
          (acc, curr) => ({
            ...acc,
            [curr.tripType]: (acc[curr.tripType] || []).concat(curr)
          }),
          {}
        )
    ).map((pair) => ({ type: pair[0], flights: pair[1] }));
  }

  bookingSorting(bookings) {
    bookings.sort((a, b) => {
      const dateA = new Date(a.flights[0].scheduledDepartureTime);
      const dateB = new Date(b.flights[0].scheduledDepartureTime);

      return dateB - dateA;
    })
  }

  bookingFiltering(bookings) {
    this.pastBookings = bookings.filter(booking => booking.upcomingBooking === false);
    if (this.pastBookings.length > 0) {
      this.hasPastBookings = true;
      this.bookingSorting(this.pastBookings);
    }
    if (this.pastBookings.length <= this.PAST_BOOKINGS_TO_DISPLAY) {
      this.displayedAllPastBookings = true;
    }
    this.upcomingBookings = bookings.filter(booking => booking.upcomingBooking === true);
    if (this.upcomingBookings.length > 0) {
      this.hasUpcomingBookings = true;
    }
    if (this.upcomingBookings.length <= this.UPCOMING_BOOKINGS_TO_DISPLAY) {
      this.displayedAllUpcomingBookings = true;
    }
  }

  navigateToCaseViewPage(event) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: event.target.dataset.id,
        objectApiName: "Case",
        actionName: "view"
      }
    });
  }

  async addBookingToCase(searchString) {
    this.error = false;
    this.showSpinner = true;
    try {
      const foundBookingIds = await addBookingToCaseApex({
        caseId: this.caseId,
        bookingReference: searchString
      });
      if (foundBookingIds == null || foundBookingIds.length == 0) {
        this.noSearchResult = true;
      }

      setTimeout(() => {
        // Timeout because bookings haven't finished updating during the await
        refreshApex(this.wiredBookingsReference);
        this.displayAddAnotherBookingForm = false;
        this.showSpinner = false;
        this.displayedAllPastBookings = false;
        this.displayedAllUpcomingBookings = false;
      }, 6000);
    } catch (error) {
      this.error = error;
      this.showSpinner = false;
    }
  }

  async removeBookingFromCase(event) {
    this.error = false;
    this.showSpinner = true;

    try {
      await removeBookingFromCaseApex({
        caseId: this.caseId,
        bookingIdentifier:
          event.target.dataset.id === "last"
            ? this.bookings[this.bookings.length - 1].bookingIdentifier
            : event.target.dataset.id
      });

      setTimeout(() => {
        // Timeout because bookings haven't finished updating during the await
        refreshApex(this.wiredBookingsReference);
        this.displayAddAnotherBookingForm = false;
        this.showSpinner = false;
      }, 6000);
    } catch (error) {
      this.error = error;
      this.displayAddAnotherBookingForm = false;
      this.showSpinner = false;
    }
  }

  async refreshBooking(event) {
    this.error = false;
    this.showSpinner = true;
    try {
      await refetchBookingDataApex({
        bookingIdentifier: event.target.dataset.id
      });

      setTimeout(() => {
        // Timeout because bookings haven't finished updating during the await
        refreshApex(this.wiredBookingsReference);
        this.displayAddAnotherBookingForm = false;
        this.showSpinner = false;
      }, 6000);
    } catch (error) {
      this.error = error;
      this.displayAddAnotherBookingForm = false;
      this.showSpinner = false;
    }
  }

  handleDisplayAllFlights(event) {
    const bookingReference = event.target.dataset.id;
    this.bookings = this.bookings.map((booking) => {
      if (booking.bookingReference === bookingReference) {
        booking.displayDetails.showAllFlights = true;
        booking.trips = this.populateTrips(booking.flights);
        booking.displayDetails.flightsVisible = `${booking.trips.reduce(
          (acc, curr) => acc + curr.flights.length,
          0
        )} of ${booking.trips.reduce(
          (acc, curr) => acc + curr.flights.length,
          0
        )}`
      }

      return booking;
    });
  }

  handleDisplayAllPassengers(event) {
    const bookingReference = event.target.dataset.id;
    this.bookings = this.bookings.map((booking) => {
      if (booking.bookingReference === bookingReference) {
        booking.displayDetails.showAllPassengers = true;
        booking.visiblePassengers = booking.passengers;
        booking.displayDetails.passengersVisible = `${booking.passengers.length} of ${booking.passengers.length}`
      }

      return booking;
    });
  }

  flipDisplayAddAnotherBookingForm() {
    this.displayAddAnotherBookingForm = !this.displayAddAnotherBookingForm;
  }

  handlePressEnterKey(event) {
    if (event.key === "Enter") {
      this.handleSearchButtonClick();
    }
  }

  handleSearchValueChange(event) {
    this.searchValue = event.target.value;
    this.noSearchResult = false;
  }

  handleSearchButtonClick() {
    if (this.searchValue != "") {
      this.noSearchResult = false;
      this.addBookingToCase(this.searchValue);
    }
  }

  handleDisplayPastBookings() {
    this.PAST_BOOKINGS_TO_DISPLAY += 5;
    if (this.pastBookings.length <= this.PAST_BOOKINGS_TO_DISPLAY) {
      this.displayedAllPastBookings = true;
    } 
  }

  handleDisplayUpcomingBookings() {
    this.UPCOMING_BOOKINGS_TO_DISPLAY += 5;
    if (this.upcomingBookings.length <= this.UPCOMING_BOOKINGS_TO_DISPLAY) {
      this.displayedAllUpcomingBookings = true;
    } 
  }

  handleAddPNRToCase(event) {
    const fields = {};
    const PNR = event.currentTarget.dataset.pnr;
    const recordInput = { fields };

    fields[Case_RECORDID_FIELD.fieldApiName] = this.recordId;
    fields[CASE_PNR_FIELD.fieldApiName] = PNR;

    updateRecord(recordInput).then(() => {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Success',
          message: 'PNR added successfully',
          variant: 'success'
        })
      );
    })
    .catch(error => {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error adding PNR',
          message: error.body.message,
          variant: 'error'
        })
      );
    });
  }
}