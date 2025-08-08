/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 */

const pnr = { label: 'PNR', fieldName: 'bookingReference', sortable: true, initialWidth: 75 };
const name = { label: 'Name', fieldName: 'lastNameSlashFirstName', sortable: true };
const phone = { label: 'Phone', fieldName: 'phoneNumber', sortable: true, initialWidth: 115 };
const email = { label: 'Email', fieldName: 'emailAddress', sortable: true };
const sClass = { label: 'Serv Class', fieldName: 'thisSegment.serviceClass', sortable: true, initialWidth: 60 };
const boardingSeq = { label: 'Boarding Seq', fieldName: 'thisSegment.boardingSequenceNumber', sortable: true };
const bClass = { label: 'Bkg Class', fieldName: 'thisSegment.bookingClass', sortable: true, initialWidth: 60 };
const status = { label: 'Status', fieldName: 'thisSegment.status', sortable: true };
const code = { label: 'Code', fieldName: 'thisSegment.statusCode', sortable: true, initialWidth: 70 };
const ssr = { label: 'SSR', fieldName: 'SSR', sortable: true, initialWidth: 70 };
const eb = { label: 'EB', fieldName: 'ebLevel', sortable: true, initialWidth: 50 };
const fqtv = { label: 'FQTV', fieldName: 'otherFQTVCarrier', sortable: true, initialWidth: 70 };

const cFlight = { label: 'Flight', fieldName: 'thisSegment.flightId', sortable: true };
const nFlight = { label: 'Outbound', fieldName: 'nextSegment.flightId', sortable: true };
const pFlight = { label: 'Inbound', fieldName: 'prevSegment.flightId', sortable: true };

export const FLIGHT_COLUMNS = [cFlight, pnr, name, phone, email, sClass, boardingSeq, bClass, status, code, ssr, eb, fqtv];
export const PREVIOUS_FLIGHT_COLUMNS = [pFlight, pnr, name, phone, email, sClass, boardingSeq, bClass, status, code, ssr, eb, fqtv];
export const NEXT_FLIGHT_COLUMNS = [nFlight, pnr, name, phone, email, sClass, boardingSeq, bClass, status, code, ssr, eb, fqtv];
export const BOOKING_COLUMNS = [pnr, name, phone, email, ssr, eb, fqtv];
export const BOOKING_FILTER_COLUMNS = [cFlight, pnr, name, phone, email, sClass, boardingSeq, bClass, status, code, ssr, eb, fqtv];