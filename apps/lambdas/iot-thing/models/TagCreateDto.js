import AWS from 'aws-sdk';

export class ThingCreateDto {
    /**
     * class ThingCreateDto
     * */

    /**
     * @property {String|null}
     * */
    _id = null;
    /**
     * @property {String|null}
     * */
    macAddress = null;
    /**
     * @property {String|null}
     * */
    locationId = null;
    /**
     * @property {String|null}
     * */
    createdAt = null;

    constructor(data) {
        this._id = AWS.util.uuid.v4();
        this.macAddress = data.macAddress;
        this.locationId = data.locationId || null;
        this.createdAt = new Date().toISOString();
    }
}
