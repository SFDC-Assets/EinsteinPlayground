import { LightningElement, api, track } from 'lwc';

export default class EinsteinGenericPlaygroundComponentLwc extends LightningElement {
	@api allModelsByType;
	@api type;
	@api iconName;

	@track selectedTab = "datasets";
	@track defaultDatasetId;
	@track defaultModelId;

	get ocrOrNer() {
		return (this.type == 'ocr' || this.type == 'text-ner');
	}

	handlePredict(event) {
		console.log('Predict event received');
		
		this.selectedTab = "prediction";

		this.defaultDatasetId = event.detail.datasetId;
		this.defaultModelId = event.detail.modelId;
	}

	handleActive(event) {
		this.selectedTab = event.target.value;
	}
}