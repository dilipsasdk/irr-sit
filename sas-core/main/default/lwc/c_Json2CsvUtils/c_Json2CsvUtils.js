export function convertToCSV(objArray, headers) {

    const actualHeaderKeys = Object.keys(headers); // create an array of the headers    
    const headersToShow = Object.values(headers); // create an array of the headers to show as CSV headers
    const data =  typeof objArray != 'object' ? JSON.parse(objArray): objArray; // convert the string to json object

    let rowEnd = '\n';
    let csvString = '';

    csvString += headersToShow.join(',');
    csvString += rowEnd;

     // loop through the data and add each row to the csv string
     for(let i=0; i < data.length; i++){
        let colValue = 0;

        // loop through the headers and add each column to the csv string
        for(let key in actualHeaderKeys) {

            if(actualHeaderKeys.hasOwnProperty(key)) {

                // Key value 
                // Ex: Id, Name
                let rowKey = actualHeaderKeys[key]; 
                // add , after every value except the first.
                if(colValue > 0){
                    csvString += ',';
                }
                // get the value from the data and add to csv 
                let value = data[i][rowKey] === undefined ? '' : data[i][rowKey];
                csvString += '"'+ value +'"';
                colValue++;
            }
        }
        csvString += rowEnd;
    }
    return csvString;
}