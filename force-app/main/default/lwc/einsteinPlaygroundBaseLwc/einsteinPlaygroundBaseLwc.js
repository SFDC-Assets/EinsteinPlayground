import { LightningElement, api } from 'lwc';


export default class EinsteinPlaygroundBaseLwc extends LightningElement { 
	showSpinner = false;

	@api changeSpinner = () => {
		this.showSpinner = !this.showSpinner;
	}

	@api setSpinnerWaiting (enableSpinner) {
		this.showSpinner = enableSpinner;
	}

	get spinnerWaiting() {
		return this.showSpinner;
	}

}