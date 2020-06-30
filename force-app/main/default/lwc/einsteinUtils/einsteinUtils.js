import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDatasetsApex from '@salesforce/apex/Einstein_PlaygroundController.getDatasets';
import getModelsApex from '@salesforce/apex/Einstein_PlaygroundController.getModels';

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
	console.log('handleErrors');
	for(var i=0; i<errors.length; i++) {
		console.log( errors[i]);
		console.log( errors[i].message);
	}
	
	// Configure error toast
	let toastParams = {
		title: "Error",
		message: "Unknown error", // Default error message
		variant: "error"
	};
	// Pass the error message if any
	if (errors && Array.isArray(errors) && errors.length > 0) {
		// Go figure, but some messages are a string object, not just a string,
		// for example, 
		// {"message":"There's currently a model for dataset 1172122 in a status of RUNNING or QUEUED. You must wait until that training process is complete before you can train the dataset again."}
		try {
			var message = JSON.parse(errors[0].message);
			toastParams.message = message.message;
		} catch(e) {
			toastParams.message = errors[0].message;
		}

		console.log(toastParams.message);
	} else if (errors && errors.body) {
		// Maybe it is an error from an LWC component Apex invocation
		toastParams.message = errors.body.message;
	} else {
		// One last try.  Maybe it's a single error, not an array
		toastParams.message = errors.message;
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

export {handleConfirmation, handleErrors, handleWarning, getDatasets, getModels}

