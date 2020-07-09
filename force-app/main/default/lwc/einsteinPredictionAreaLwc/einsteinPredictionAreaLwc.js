import { LightningElement, api } from 'lwc';

export default class EinsteinPredictionAreaLwc extends LightningElement {
	@api type;
	@api iconName;
	@api defaultDatasetId;
	@api defaultModelId;

	modelId;

	get typeSupportsMassUpdate() {
		return (this.type == 'image') || (this.type == 'text-sentiment') || (this.type == 'text-intent');
	}
}