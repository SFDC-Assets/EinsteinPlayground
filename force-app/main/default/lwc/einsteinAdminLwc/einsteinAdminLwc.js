import { LightningElement } from 'lwc';
import EINSTEIN_IMAGES from '@salesforce/resourceUrl/einstein_images';

export default class EinsteinAdminLwc extends LightningElement {
	selectedMenu = "usage";
	pictureSrc = EINSTEIN_IMAGES + '/einstein_images/einstein_header_icon.svg';

	get usageMenuSelected() {
		return (this.selectedMenu == "usage");
	}

	get setupMenuSelected() {
		return (this.selectedMenu == "setup");
	}

	get usageMenuClass() {
		return (this.selectedMenu == 'usage' ? 'slds-is-active' : '');
	}

	get setupMenuClass() {
		return (this.selectedMenu == 'setup' ? 'slds-is-active' : '');
	}

	selectUsage(event) {
		this.selectedMenu = "usage";
	}

	selectSetup(event) {
		this.selectedMenu = "setup";
	}
}