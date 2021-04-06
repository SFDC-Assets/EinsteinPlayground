import { LightningElement,api } from 'lwc';

export default class EinsteinProbabilityViewerLwc extends LightningElement {
	@api probability;

	get attributesNotBlank() {
		return (this.probability &&
			this.probability.attributes &&
			(Object.keys(this.probability.attributes).length) > 0);
	}

	get isPersonType() {
		return (this.probability &&
			this.probability.normalizedData &&
			this.probability.normalizedData.type === 'person');
	}

}