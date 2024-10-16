import { getTableKey } from '../utils/index.js';
import { THINGS } from '../constants.js';

export class ThingsRepo {

    repository = null;

    static repositoryInstance = null;

    static setRepository(repository) {
        ThingsRepo.repositoryInstance = repository;
    }

    constructor() {
        this.repository = ThingsRepo.repositoryInstance;
    }

    async save(data) {
        const pkValue = getTableKey(THINGS, data.macAddress);
        const skValue = data.owner;
        return this.repository.save({ pkValue, skValue, data });
    }

    async readByMac(macAddress) {
        const pkValue = getTableKey(THINGS, macAddress);
        console.log('pkValue ', pkValue);
        const records = await this.repository.readByPk(pkValue);
        console.log('records: ', records);
        return records.map(record => record['data']);
    }

    async remove(macAddress) {
        const pkValue = getTableKey(THINGS, macAddress);
        return this.repository.remove(pkValue);
    }
}
