import { LightningElement, api } from 'lwc';

export default class EinsteinF1DisplayerLwc extends LightningElement {

	@api f1;

	get isArray() {
		return (Array.isArray(this.f1));
	}
}