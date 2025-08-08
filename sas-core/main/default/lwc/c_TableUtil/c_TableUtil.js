/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description Common table util functionality.
 */

function sortData(data, fieldName, direction) {
    const isReverse = direction === 'asc' ? 1 : -1;
    data.sort((x, y) => {
        x = x[fieldName] || '';
        y = y[fieldName] || '';
        return x > y ? isReverse : -isReverse;
    });
}

function filterData(data, filterParams) {
    const filterEntries = Object.entries(filterParams);
    if (filterEntries.length === 0 ) return [...data];
    const evalField = (row, fieldName, value) => 
        (row[fieldName] === value) || (!row[fieldName] && value === null) || (row[fieldName] && value === '*') 
            || (value === 'NOTADOC' && (!row[fieldName] || (row[fieldName] && !(row[fieldName]).includes('ADOC')))) 
            || (row[fieldName] && value === 'ADOC' && row[fieldName].includes(value));
    return data.filter(row => {
        return filterEntries.every(entry => {
            const filterValues = Array.isArray(entry[1]) ? entry[1] : [entry[1]];
            return filterValues.some(val => evalField(row, entry[0], val));
        });
    });
}

function unFlatten(data) {
    "use strict";
    if (Object(data) !== data || Array.isArray(data))
        return data;
    let result = {}, cur, prop, idx, last, temp;
    for(const p in data) {
        cur = result, prop = "", last = 0;
        do {
            idx = p.indexOf(".", last);
            temp = p.substring(last, idx !== -1 ? idx : undefined);
            cur = cur[prop] || (cur[prop] = (!isNaN(parseInt(temp)) ? [] : {}));
            prop = temp;
            last = idx + 1;
        } while(idx >= 0);
        cur[prop] = data[p];
    }
    return result[""];
}

function flatten(data) {
    const result = {};
    function recurse (cur, prop) {
        if (Object(cur) !== cur) {
            result[prop] = cur;
        } else if (Array.isArray(cur)) {
            const l = cur.length;
            for(let i=0, l = cur.length; i<l; i++)
                recurse(cur[i], prop ? prop+"."+i : ""+i);
            if (l === 0)
                result[prop] = [];
        } else {
            let isEmpty = true;
            for (const p in cur) {
                isEmpty = false;
                recurse(cur[p], prop ? prop+"."+p : p);
            }
            if (isEmpty) {
                result[prop] = {};
            }
        }
    }
    recurse(data, "");
    return result;
}

export {sortData, filterData, unFlatten, flatten}