import { LightningElement, track, api } from 'lwc';
import { handleConfirmation, handleWarning, handleErrors, getModels } from 'c/einsteinUtils';

import deleteModel from '@salesforce/apex/Einstein_PlaygroundController.deleteModel';

export default class EinsteinDatasetDetailsLwc extends LightningElement {

	@api type;
	@api aiDataset;


	@track models;

	hasRendered = false;
	baseCompName = 'c-einstein-playground-base-lwc';

	renderedCallback() {
		console.log('renderedCallback');

		if (!this.hasRendered) {
			this.hasRendered = true;

			this.onLoadModels();
		}
	}

	onLoadModels() {
//		this.template.querySelector(this.baseCompName).setSpinnerWaiting(true);
		getModels(this.aiDataset.id, this.type)
		.then(result => {
//			this.template.querySelector(this.baseCompName).setSpinnerWaiting(false);
			console.log('models received', result);
			// Hack so datasets are extensible
			this.models = JSON.parse(JSON.stringify(result));

			this.models.forEach(function (model) {
				model.ready = (model.status == 'SUCCEEDED');
				model.running = (model.status == 'RUNNING');
				model.progressPct = model.progress * 100;
			});
		})
		.catch(error => {
//			this.template.querySelector(this.baseCompName).setSpinnerWaiting(false);
			handleErrors(error);
			console.log("Error: " + error.body);
		});
	}

	onDeleteModel(event) {
		var selectedModelId = event.currentTarget.getAttribute('data-label');

		deleteModel({
			modelId: selectedModelId,
			dataType: this.type
		})
			.then(result => {
				handleConfirmation("Model " + selectedModelId + " deletion requested successfully");
			})
			.catch(error => {
				handleErrors(error);
		})

	}

	toggleDetails(event) {
		let self = this;
		let modelIndex = event.currentTarget.getAttribute('data-label');

		this.models.forEach(function (row, index) {
			if (row.open && index != modelIndex) {
				// you opened some other one, close this one
				row.open = false;
			} else if (row.open && index == modelIndex) {
				// you're trying to toggle closed the currently open one
				row.open = false;
			} else if (!row.open && index == modelIndex) {
				// it was closed and you're trying to open it
				if (row.ready) {
					row.open = true;
				}
			}
		});
	}

	get header() {
		return 'Metrics for ' + this.aiDataset.name + ' / ' + this.model;
	}

}