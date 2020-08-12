import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDatasetsApex from '@salesforce/apex/Einstein_PlaygroundController.getDatasets';
import getModelsApex from '@salesforce/apex/Einstein_PlaygroundController.getModels';
import getFeatureCodeEnabledApex from '@salesforce/apex/Einstein_PlaygroundController.getFeatureCodeEnabled';

const getDatasets = (type) => {

	let p = new Promise(function (resolve, reject) {
		getDatasetsApex({
			dataType : type
		})
		.then(result => {
			console.log('datasets received by utils');
			resolve(result);
		})
		.catch(error => {
			reject(error.body);
		});
	
	})
	return p;
}

const getModels = (datasetId, type) => {

	let p = new Promise(function (resolve, reject) {
		getModelsApex({
			datasetId: datasetId,
			dataType : type
		})
		.then(result => {
			console.log('models received by utils');
			resolve(result);
		})
		.catch(error => {
			reject(error.body);
		});
	
	})
	return p;
}

const getFeatureCodeEnabled = () => {

	let p = new Promise(function (resolve, reject) {
		getFeatureCodeEnabledApex()
		.then(result => {
			console.log('FeatureCodeEnabled recieved by utils');
			resolve(result);
		})
		.catch(error => {
			reject(error.body);
		});
	
	})
	return p;
}

const handleConfirmation = (message) => {
	console.log('handleConfirmation');
	const evt = new ShowToastEvent({
		title: "Confirmation",
		message: message,
		variant: "success",
	});
	!window.dispatchEvent(evt);
}

const handleErrors = (errors) => {
	console.log('handleErrors: ' + JSON.stringify(errors));
	
	// Configure error toast
	let toastParams = {
		title: "Error",
		message: "Unknown error", // Default error message
		variant: "error"
	};

	var singleError;
	// Error could be an array.  Just toast the first one
	if (errors && Array.isArray(errors) && errors.length > 0) {
		for (var i = 0; i < errors.length; i++) {
			console.log(errors[i]);
			console.log(errors[i].message);
		}
		singleError = errors[0];

	} else if (errors && errors.body) {
		// Maybe it is an error from an LWC component Apex invocation, which has a body parameter
		singleError = errors.body;

	} else if (errors && errors.message) {
		// Maybe it is just a single error itself
		singleError = errors;
	}

	// Go figure, but some messages are a string object, not just a string,
	// for example, 
	// {"message":"There's currently a model for dataset 1172122 in a status of RUNNING or QUEUED. You must wait until that training process is complete before you can train the dataset again."}
	// Or worse yet, a string within a stringified object:
	// errors.body.message = "{"message":"{\"message\":\"There's currently a model for dataset 1101083 in a status of RUNNING or QUEUED. You must wait until that training process is complete before you can train the dataset again.\"}"}"
	try {
		var testMessage1 = JSON.parse(singleError.message);
		try {
			var testMessage2 = JSON.parse(testMessage1.message).message;
			toastParams.message = testMessage2;
		} catch (e) {
			toastParams.message = testMessage1.message;			
		}
	} catch(e) {
		toastParams.message = singleError.message;
	}

	// Fire error toast
	const evt = new ShowToastEvent(toastParams);
	!window.dispatchEvent(evt);

}

const handleWarning = (warning) => {
	console.log('handleWarning');
		
	// Configure error toast
	let toastParams = {
		title: "Warning!",
		message: warning,
		variant: "warning"
	};
	// Fire error toast
	const evt = new ShowToastEvent(toastParams);
	!window.dispatchEvent(evt);

}

export {handleConfirmation, handleErrors, handleWarning, getDatasets, getModels, getFeatureCodeEnabled}

