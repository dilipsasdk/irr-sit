/**
 * @description Common string utilities
 */

/**
 * Capitalises the first letter of a string and returns the result.
 *
 * @param {string} stringToFormat
 * @returns Capitalised version of the input.
 */
const toCapitalCase = (stringToFormat) => {
  if (typeof stringToFormat !== "string" || stringToFormat.length < 1) {
    return "";
  } else {
    return (
      stringToFormat.charAt(0).toUpperCase() +
      stringToFormat.slice(1).toLowerCase()
    );
  }
};

export { toCapitalCase };
