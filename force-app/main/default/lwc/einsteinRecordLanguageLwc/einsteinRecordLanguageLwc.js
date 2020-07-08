import { LightningElement, api, wire, track } from 'lwc';
import { handleConfirmation, handleWarning, handleErrors  } from 'c/einsteinUtils';

import getRecordAnalysis from '@salesforce/apex/Einstein_RecordLanguageController.getRecordAnalysis';
import getLanguagePhrase from '@salesforce/apex/Einstein_RecordLanguageController.getLanguagePhrase';
import savePredictionValue from '@salesforce/apex/Einstein_RecordLanguageController.savePredictionValue';

export default class EinsteinRecordLanguageLwc extends LightningElement { 

	// Design Attributes
	@api cardLabel;
	@api modelId;
	@api fieldName;
	@api feedback;
	@api saveToField;

	@api recordId;

	predictionList;
	error;

	@wire(getRecordAnalysis,
		{
			recordId: '$recordId',
			modelId: '$modelId',
			fieldName: '$fieldName'
		}) 
		wiredRecordAnalysis({ error, data }) {
			if (data) {
				console.log('wiredRecordAnalysis received data');	
				this.predictionList = data.map((item) => {
					var temp = Object.assign({}, item);
					temp.liked = false;
					temp.icon = "utility:like";
					return temp;
				});
				this.error = undefined;
				try {
					this.template.querySelector('c-einstein-platform-card-lwc').hasData = true;
				} catch (err) {
					console.log('Child not ready yet.  This is xpected');
				}
			} else if (error) {
				this.error = error;
				this.predictionList = undefined;
			}
	}
		
	@wire(getLanguagePhrase,
		{
			recordId: '$recordId',
			fieldName: '$fieldName'
		}) intentPhrase;


	savePrediction() {

		console.log('savePrediciton: ' + this.recordId + ' ' + this.saveToField + ' ' + this.predictionList[0].label);
		
		savePredictionValue({
			recordId: this.recordId,
			fieldName: this.saveToField,
			value: this.predictionList[0].label
		})
			.then(result => {
				handleConfirmation('Einstein prediction saved successfully.');
			})
			.catch(error => {
				handleErrors(error);
			});

	}
}