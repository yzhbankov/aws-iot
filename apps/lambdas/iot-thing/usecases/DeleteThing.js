import { ThingsRepo, NotFoundError } from '../models/index.js';

export class DeleteThing {
    async execute({ macAddress }) {
        const things = await new ThingsRepo().readByMac(macAddress);
        if (!things.length) {
            throw new NotFoundError(`Thing with MAC ${macAddress} not found`)
        }

        return new ThingsRepo().remove(things[0].macAddress);
    }
}
