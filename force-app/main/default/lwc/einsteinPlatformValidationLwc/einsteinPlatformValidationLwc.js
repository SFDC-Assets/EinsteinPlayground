import { LightningElement, api, track, wire } from 'lwc';
import validateSetup from '@salesforce/apex/Einstein_PlaygroundController.validateSetup';
import { handleErrors } from 'c/einsteinUtils';

export default class EinsteinPlatformValidationLwc extends LightningElement {

	@track connectionStatus;
	showError;

	connectionStatus;

	connectedCallback() {
		validateSetup() 
			.then(result => {
				this.connectionStatus = result;
			})
			.catch(error => {
				handleErrors(error);
		})
	}

	get connectionStatusIsWorking() {
		return this.connectionStatus && (this.connectionStatus.status == 'Working');
	}

	get connectionStatusIsIncomplete() {
		return this.connectionStatus && (this.connectionStatus.status == 'Configuration Incomplete');
	}

	get connectionStatusIsError() {
		return this.connectionStatus && (this.connectionStatus.status == 'Connection Error');
	}

	handleShowError(event) {
		this.showError = !this.showError;
	}
}