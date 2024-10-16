import { ReadThing, AddThing, DeleteThing } from '../usecases/index.js';
import { makeRequestHandler } from '../system/index.js';

export class Routers {
    static async get({ body, param }) {
        return makeRequestHandler(ReadThing, { macAddress: param });
    }
    static async post({ body, param }) {
        return makeRequestHandler(AddThing, { data: body });
    }
    static async del({ body, param }) {
        return makeRequestHandler(DeleteThing, { macAddress: param });
    }
}
