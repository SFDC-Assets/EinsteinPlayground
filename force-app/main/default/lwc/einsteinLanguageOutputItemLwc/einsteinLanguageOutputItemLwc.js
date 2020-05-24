import { LightningElement, api } from 'lwc';
import { handleConfirmation, handleWarning, handleErrors  } from 'c/einsteinUtils';

import createFeedbackLanguageExample from '@salesforce/apex/Einstein_PlaygroundController.createFeedbackLanguageExample';

export default class EinsteinLanguageOutputItemLwc extends LightningElement {
	@api label;
	@api probability;
	@api liked;
	@api icon;
	@api modelId;
	@api intentPhrase;
	@api feedback;

	get isHighProbability() {
		return (this.probability > 0.7);
	}
	get isMediumProbability() {
		return ((this.probability <= 0.7) && (this.probability > 0.5));
	}
	get isLowProbability() {
		return (this.probability <= 0.5);
	}

	handleFeedback() {
		console.log('handleFeedback');

		if (this.modelId == "CommunitySentiment") {
		  handleErrors([{message: 'Feedback cannot be created for community models'}]);
		  return;
		}
	
		this.liked = true;
		this.icon = 'utility:like';

		createFeedbackLanguageExample({
            modelId: this.modelId,
			expectedLabel: this.label,
			text: this.intentPhrase
        })
		.then(result => {
			handleConfirmation('Feedback Received.');
		})
		.catch(error => {
			handleErrors(error.body);
		});
	}

}