import { LightningElement, api } from 'lwc';

export default class EinsteinLanguageOutputLwc extends LightningElement {

	// Design Attributes
	@api modelId;
	@api predictionList;
	@api feedback;
	@api intentPhrase;

	@api models;

}