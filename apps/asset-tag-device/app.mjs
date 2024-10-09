// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0
import awsIot from 'aws-iot-device-sdk';

//
// Replace the values of '<YourUniqueClientIdentifier>' and '<YourCustomEndpoint>'
// with a unique client identifier and custom host endpoint provided in AWS IoT.
// NOTE: client identifiers must be unique within your AWS account; if a client attempts
// to connect with a client identifier which is already in use, the existing
// connection will be terminated.
//
const device = awsIot.device({
    keyPath: "/Users/yzhbankov/Documents/petprojects/aws-iot/certs/bf63e8aec4c513545b98b6a03db94187714cb218835d5b8e78c9fffcf43fbfd4-private.pem.key",
    certPath: "/Users/yzhbankov/Documents/petprojects/aws-iot/certs/bf63e8aec4c513545b98b6a03db94187714cb218835d5b8e78c9fffcf43fbfd4-certificate.pem.crt",
    caPath: "/Users/yzhbankov/Documents/petprojects/aws-iot/certs/AmazonRootCA1 (1).pem",
    clientId: "prod-yz-iot-thing",
    host: "a2ndfre2pmsyjx-ats.iot.us-east-1.amazonaws.com"
});

let i = 0;
//
// Device is an instance returned by mqtt.Client(), see mqtt.js for full
// documentation.
//
device
    .on('connect', function () {
        console.log('connect');
        device.subscribe('topic_1');
        setInterval(() => {
            i += 1;
            device.publish('topic_2', JSON.stringify({device_id: 1, x: 0, y: 0, z: 0, location: 1, cnt: i, now: new Date().toISOString()}));
            console.log('publish ', i);
        }, 500);

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
