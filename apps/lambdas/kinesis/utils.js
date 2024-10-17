/**
 * @function
 * @param {String} entity - entity name
 * @param {String} value - key target value
 * @return {String}
 * */
export function getTableKey(entity, value) {
    return `${entity}_${value}`
}

/**
 * @function
 * @param {String} value - string value
 * @return {Object}
 * */
export function parseSafe(value) {
    try {
        return JSON.parse(value);
    } catch (e) {
        return null;
    }
}
