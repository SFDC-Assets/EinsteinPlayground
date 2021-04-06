import { LightningElement, api } from 'lwc';

export default class EinsteinPlatformCardLwc extends LightningElement {
	@api cardLabel = '';
	@api hasData = false;

}