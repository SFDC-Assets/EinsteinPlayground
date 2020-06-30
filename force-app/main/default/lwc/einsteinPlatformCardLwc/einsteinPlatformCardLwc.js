import { LightningElement, api } from 'lwc';

export default class EinsteinPlatformCardLwc extends LightningElement {
	@api cardLabel = '';
	@api hasData = false;
	baseComponentName = 'c-einstein-playground-base-lwc';

	@api changeSpinner = () => {
		this.template.querySelector(this.baseComponentName).changeSpinner();
	}

	@api setSpinnerWaiting (enableSpinner) {
		this.template.querySelector(this.baseComponentName).setSpinnerWaiting(enableSpinner);
	}

	get spinnerWaiting() {
		return this.template.querySelector(this.baseComponentName).spinnerWaiting();
	}

}