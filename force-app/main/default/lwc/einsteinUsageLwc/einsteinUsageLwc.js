import { LightningElement } from 'lwc';
import { handleConfirmation, handleWarning, handleErrors, getDatasets, getFeatureCodeEnabled } from 'c/einsteinUtils';
import getUsage from '@salesforce/apex/Einstein_PlaygroundController.getUsage';

export default class EinsteinUsageLwc extends LightningElement {

	usage;

	connectedCallback() {
		getUsage() 
			.then(result => {
				this.usage = result;

				// In format "2020-08-01T00:00:00.000+0000".  Needs to be "2020-08-01T00:00:00.000Z"
				this.usage.forEach(usage => {
					usage.startsAt = usage.startsAt.replace("+0000", "Z");
					usage.endsAt = usage.endsAt.replace("+0000", "Z");	
				})
			})
			.catch(error => {
				handleErrors(error);
		})
	}
}