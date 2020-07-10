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

	@wire(getSettings)
	wiredGetSettings({ error, data }) {
		if (data) {
			console.log('getSettings returned data: ' + data);	
			this.settings = data;
			this._error = undefined;
		
		} else if (error) {
			handleErrors(error);
			this._error = error;
			this.settings = undefined;
		}
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

	handleUploadFinished(event) {
		var uploadedFiles = event.detail.files;

		for (var i = 0; i < uploadedFiles.length; i++) {
			console.log(uploadedFiles[i].name + ' - ' + uploadedFiles[i].documentId);
			contentId = uploadedFiles[i].documentId;
			filename = uploadedFiles[i].name;
		}

		updatePemFile({ documentId: contentId })
			.then(result => {
				var certName =  result;
				this.settings.einsteinplay__CertName__c  = certName;
			})
			.catch(error => {
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
			})
			.catch(error => {
				handleErrors(error);
		})

	}
}