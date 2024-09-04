// const AWS = require('aws-sdk');
// const dynamoDB = new AWS.DynamoDB();

export const handler = async (event) => {
    const records = event.records.map(async (record) => {
        console.log(record);
        // Decode the base64 data
        const payload = Buffer.from(record.data, 'base64').toString('utf-8');
        const parsedPayload = JSON.parse(payload);

        // Fetch metadata from DynamoDB
        // const params = {
        //     TableName: 'your_table',
        //     Key: {
        //         'your_key': { S: parsedPayload.key }
        //     }
        // };

        // let metadata;
        // try {
        //     const result = await dynamoDB.getItem(params).promise();
        //     metadata = result.Item || {};
        // } catch (error) {
        //     console.error(`Error fetching metadata for key ${parsedPayload.key}:`, error);
        //     return {
        //         recordId: record.recordId,
        //         result: 'ProcessingFailed',
        //         data: record.data
        //     };
        // }

        // Merge the payload with metadata
        const extendedData = {
            ...parsedPayload,
            ts: new Date().toISOString()
        };

        // Encode the merged data back to base64
        const encodedData = Buffer.from(JSON.stringify(extendedData)).toString('base64');

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
