import { LightningElement } from 'lwc';
import { handleConfirmation, handleWarning, handleErrors, getDatasets, getFeatureCodeEnabled } from 'c/einsteinUtils';

export default class EinsteinPlaygroundLwc extends LightningElement {

	isFeatureCodeEnabled;
	
	renderedCallback() {
		getFeatureCodeEnabled() 
		.then(result => {
			this.isFeatureCodeEnabled = result;
		})
		.catch(error => {
			this.isFeatureCodeEnabled = false;
			handleErrors(error);
	})

	}
}