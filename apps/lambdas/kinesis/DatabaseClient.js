import AWS from 'aws-sdk';

export class DatabaseClient {
    #table = null;

    constructor(tableName) {
        this.#table = new AWS.DynamoDB.DocumentClient({
            params: { TableName: tableName }
        });
    }

    async readByPk(pkValue) {
        try {
            const result = await this.#table.query({
                KeyConditionExpression: 'PK = :pkValue',
                ExpressionAttributeValues: { ':pkValue': pkValue }
            }).promise();
            return result['Items'];
        } catch (e) {
            console.error('[DatabaseClient] read: ', e);
            return null;
        }
    }
}
