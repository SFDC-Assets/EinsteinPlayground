import { LightningElement, api } from 'lwc';

export default class EinsteinPlatformCardLwc extends LightningElement {
	@api cardLabel = '';
	@api hasData = false;

	@api changeSpinner = () => {
		this.template.querySelector('c-einstein-playground-base-lwc').changeSpinner();
	}

	@api setSpinnerWaiting (enableSpinner) {
		this.template.querySelector('c-einstein-playground-base-lwc').setSpinnerWaiting(enableSpinner);
	}

	get spinnerWaiting() {
		return this.template.querySelector('c-einstein-playground-base-lwc').spinnerWaiting();
	}

}