import { LightningElement, wire } from 'lwc';
import { handleConfirmation, handleWarning, handleErrors, getDatasets, getFeatureCodeEnabled } from 'c/einsteinUtils';
import getMyUserId from '@salesforce/apex/Einstein_PlaygroundController.getMyUserId';
import getSettings from '@salesforce/apex/Einstein_PlaygroundController.getSettings';
import updatePemFile from '@salesforce/apex/Einstein_PlaygroundController.updatePemFile';
import saveSettings from '@salesforce/apex/Einstein_PlaygroundController.saveSettings';
import deleteSettings from '@salesforce/apex/Einstein_PlaygroundController.deleteSettings';

export default class EinsteinPlatformConfigureSetupLwc extends LightningElement {

	settings;
	myUserId;
	_error;
	pemUploaded;

	connectedCallback() {
		this.getSettings();
	}

	getSettings() {
		getSettings()
			.then(result => {
				this.settings = result;
			})
			.catch(error => {
				handleErrors(error);
		})
	}

	@wire(getMyUserId)
	wiredGetMyUserId({ error, data }) {
		if (data) {
			console.log('getMyUserId returned data: ' + data);	
			this.myUserId = data
			this._error = undefined;
		
		} else if (error) {
			console.log('getMyUserId failed with: ' + JSON.stringify(error));
			handleErrors(error);
			this._error = error;
			this.myUserId = undefined;
		}
	}

	onEmailChange(event) {
		this.settings.einsteinplay__Einstein_EMail__c = event.target.value;
	}

	onFeatureCodeChange(event) {
		this.settings.einsteinplay__FeatureCode__c = event.target.value;
	}

	handleUploadFinished(event) {
		var uploadedFiles = event.detail.files;
		var contentId;
		var filename;

		for (var i = 0; i < uploadedFiles.length; i++) {
			console.log(uploadedFiles[i].name + ' - ' + uploadedFiles[i].documentId);
			contentId = uploadedFiles[i].documentId;
			filename = uploadedFiles[i].name;
		}

		updatePemFile({ documentId: contentId })
			.then(result => {
				var certName =  result;
				this.pemUploaded = true;
			})
			.catch(error => {
				this.pemUploaded = false;
				handleErrors(error);
		})

	}

	save(event) {
		saveSettings({ settings: this.settings})
			.then(result => {
				handleConfirmation('Settings have been saved');
			})
			.catch(error => {
				handleErrors(error);
		})

	}

	delSettings(event) {
		deleteSettings()
			.then(result => {
				handleWarning("All Einstein Settings have been DELETED!");
				this.pemUploaded = false;
				this.getSettings();
			})
			.catch(error => {
				handleErrors(error);
		})

	}
}