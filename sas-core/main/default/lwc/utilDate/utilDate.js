/**
 * @description Common date utilities
 */

/**
 * Transforms an ISO 8601 date string into a user friendly display format.
 *
 * @param {string} stringToFormat The ISO 8601 string to format
 * @param {"date" | "time" | undefined} dateOrTime Whether just date, just time or both should be returned.
 * @returns String containting input date formatted for display
 */
const formattedDateString = (stringToFormat, dateOrTime) => {
  if (typeof stringToFormat !== "string" || stringToFormat.length === 0) {
    return "";
  }

  // Parsing date manually just in case.
  const [datePart, timePart] = stringToFormat.split("T");
  if (!datePart || !timePart) {
    return "";
  }
  const dateParts = datePart.split("-");
  const timeParts = timePart.split(":");

  const date = new Date(
    dateParts[0],
    Number(dateParts[1]) - 1, // Date constructor months start from 0 = Jan
    dateParts[2],
    timeParts[0],
    timeParts[1],
    timeParts[2]
  );

  let formatOptions = {};

  if (dateOrTime === "date") {
    formatOptions = {
      year: "numeric",
      month: "short",
      day: "2-digit"
    };
  } else if (dateOrTime === "time") {
    formatOptions = {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false
    };
  } else {
    formatOptions = {
      year: "numeric",
      month: "short",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      hour12: false
    };
  }

  return new Intl.DateTimeFormat(undefined, formatOptions).format(date);
};

/**
 * Transforms a number of minutes into display string of format Xh YYm.
 *
 * @param {number} minutesToFormat
 * @returns Input minutes as the transformed string.
 */
const minutesToHoursAndMinutes = (minutesToFormat) => {
  if (!minutesToFormat) {
    return "0h 00m";
  } else {
    const hours = Math.floor(minutesToFormat / 60);
    const minutes = minutesToFormat - hours * 60;

    return `${hours}h ${minutes < 10 ? "0" : ""}${minutes}m`;
  }
};

export { formattedDateString, minutesToHoursAndMinutes };
