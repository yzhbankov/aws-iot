import { ThingsRepo, ThingCreateDto, UnprocessableEntityError } from '../models/index.js';

export class AddThing {
    async execute({ data }) {
        const thing = await new ThingsRepo().readByMac(data.macAddress);
        if (thing) {
            throw new UnprocessableEntityError(`Thing with MAC address ${data.macAddress} already exist`)
        }
        return new ThingsRepo().save(new ThingCreateDto(data));
    }
}
