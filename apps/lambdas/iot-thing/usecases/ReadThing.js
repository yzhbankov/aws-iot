import { ThingsRepo } from '../models/index.js';

export class ReadThing {
    async execute({ macAddress }) {
        return await new ThingsRepo().readByMac(macAddress);
    }
}
