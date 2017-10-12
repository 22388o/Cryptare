const functions = require('firebase-functions');
const admin = require('firebase-admin')
admin.initializeApp(functions.config().firebase);

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
exports.helloWorld = functions.https.onRequest((request, response) => {
	response.send("Hello from Firebase!");
});

exports.btcPriceNotification = functions.https.onRequest((req, res) => {
	const ref = admin.database().ref();
	const devices = []

	ref.child('user_ids').once('value').then(snap => {
		snap.forEach(childSnap => {
			const device = childSnap.val();
			devices.push(device)
		});
		return devices;
	}).then(devices => {
		console.log(devices)

		const payload = {
			notification: {
				title: 'Cryptare',
				body: 'Check out the Bitcoin Price! 😲',
			}
		};

		return admin.messaging().sendToDevice(devices, payload).then(() => {
			res.send("Successfully sent message");
		}).catch(error => {
			res.send(error);
		});
	});
});
