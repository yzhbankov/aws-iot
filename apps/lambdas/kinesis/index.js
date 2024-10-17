import { DatabaseClient } from './DatabaseClient';
import { getTableKey, parseSafe } from './utils';

const entity = 'THINGS';
const DYNAMODB_TABLE_NAME = 'prod_iot_things_table';
const db = new DatabaseClient(DYNAMODB_TABLE_NAME);

export const handler = async (event) => {
    const records = event.records.map(async (record) => {
        const payload = Buffer.from(record.data, 'base64').toString('utf-8');
        const parsedPayload = parseSafe(payload);
        let locationId = null;

        if (parsedPayload && parsedPayload.macAddress) {
            const result = await db.readByPk(getTableKey(entity, parsedPayload.macAddress));
            if (result && result.length > 0) {
                const deviceMetadata = result[0]['data'];
                locationId = deviceMetadata ? deviceMetadata.locationId : null;
            }
        }

        // Encode the merged data back to base64
        const encodedData = Buffer.from(JSON.stringify({ ...parsedPayload, locationId })).toString('base64');

        // Return the transformed record
        return {
            recordId: record.recordId,
            result: 'Ok',
            data: encodedData
        };
    });

    // Wait for all records to be processed
    const transformedRecords = await Promise.all(records);

    return { records: transformedRecords };
};
