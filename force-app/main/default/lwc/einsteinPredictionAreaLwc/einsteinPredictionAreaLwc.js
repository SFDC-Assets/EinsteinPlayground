import { LightningElement, api } from 'lwc';

export default class EinsteinPredictionAreaLwc extends LightningElement {
	@api type;
	@api allModelsByType;
	@api iconName;

	modelId;

	get typeSupportsMassUpdate() {
		return (this.type == 'image') || (this.type == 'text-sentiment') || (this.type == 'text-intent');
	}
}