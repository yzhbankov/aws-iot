import { IoTClient, CreateThingCommand, CreateKeysAndCertificateCommand, AttachThingPrincipalCommand, AttachPolicyCommand } from '@aws-sdk/client-iot';
import { ThingsRepo, ThingCreateDto, UnprocessableEntityError } from '../models/index.js';

// Initialize AWS IoT and IoT DataPlane clients
const iotClient = new IoTClient({ region: process.env.AWS_REGION });

export class AddThing {
    async execute({ data }) {
        const things = await new ThingsRepo().readByMac(data.macAddress);
        if (things.length > 0) {
            throw new UnprocessableEntityError(`Thing with MAC address ${data.macAddress} already exist`)
        }
        const thing = await new ThingsRepo().save(new ThingCreateDto(data));

        const thingName = `thing-${data.macAddress}`;
        // 1. Create the IoT Thing
        const createThingCommand = new CreateThingCommand({ thingName });
        await iotClient.send(createThingCommand);

        // 2. Create a certificate for the IoT Thing
        const createKeysAndCertCommand = new CreateKeysAndCertificateCommand({
            setAsActive: true, // Automatically activates the certificate
        });
        const createCertResponse = await iotClient.send(createKeysAndCertCommand);

        // 3. Attach the certificate to the IoT Thing
        const attachThingPrincipalCommand = new AttachThingPrincipalCommand({
            principal: createCertResponse.certificateArn,
            thingName,
        });
        await iotClient.send(attachThingPrincipalCommand);

        // 4. Attach a policy to the certificate (replace with your policy name)
        const policyName = process.env.POLICY_NAME; // Ensure this environment variable is set
        const attachPolicyCommand = new AttachPolicyCommand({
            policyName,
            target: createCertResponse.certificateArn,
        });
        await iotClient.send(attachPolicyCommand);

        return {
            ...thing,
            thingName,
            certificateArn: createCertResponse.certificateArn,
            certificatePem: createCertResponse.certificatePem,
            privateKey: createCertResponse.keyPair.PrivateKey,
            publicKey: createCertResponse.keyPair.PublicKey,
        }
    }
}
