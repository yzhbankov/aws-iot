import { DatabaseClient, ThingsRepo } from './models/index.js';
import { controller } from './system/index.js';
import { Routers } from './routers/index.js';


ThingsRepo.setRepository(new DatabaseClient('prod_iot_things_table'));

export const handler = async (event) => {
    try {
        return controller(Routers)(event['httpMethod'], event);
    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message }),
            headers: {
                'Content-Type': 'application/json'
            }
        };
    }
};
