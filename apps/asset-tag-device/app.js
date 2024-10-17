import awsIot from 'aws-iot-device-sdk';

const SUB_TOPIC = 'topic_1';
const PUB_TOPIC = 'topic_2';
const IOT_HIST = 'a2ndfre2pmsyjx-ats.iot.us-east-1.amazonaws.com';
const CLIENT_ID = 'prod-yz-iot-thing';
const KEY_PATH = '/Users/yzhbankov/Documents/petprojects/aws-iot/certs/iot_private_key (12).pem';
const CERT_PATH = '/Users/yzhbankov/Documents/petprojects/aws-iot/certs/iot_certificate (12).pem';
const CA_PATH = '/Users/yzhbankov/Documents/petprojects/aws-iot/certs/AmazonRootCA1 (1).pem';
const MAC_ADDRESS = '000000000001';

function getMessage() {
    return {
        macAddress: MAC_ADDRESS,
        ts: new Date().toISOString(),
        temperature: Math.floor(Math.random() * 201) - 100
    }
}

const device = awsIot.device({
    keyPath: KEY_PATH,
    certPath: CERT_PATH,
    caPath: CA_PATH,
    clientId: CLIENT_ID,
    host: IOT_HIST
});

device
    .on('connect', function () {
        console.log('Device connected to IoT');
        device.subscribe(SUB_TOPIC);
        console.log(`Subscribed to ${SUB_TOPIC} topic`);

        setInterval(() => {
            const message = getMessage();
            device.publish(PUB_TOPIC, JSON.stringify(message));
            console.log('Sent data: ', JSON.stringify(message));
        }, 1_000);
    });

device
    .on('message', function (topic, payload) {
        console.log('message', topic, payload.toString());
    });

device.on('error', function (error) {
    console.error('Error:', error);
});

device.on('close', function () {
    console.log('Connection closed');
});

device.on('reconnect', function () {
    console.log('Reconnecting');
});

device.on('offline', function () {
    console.log('Device is offline');
});
