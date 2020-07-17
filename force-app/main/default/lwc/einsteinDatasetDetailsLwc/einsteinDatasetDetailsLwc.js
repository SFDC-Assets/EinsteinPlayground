import { LightningElement, track, api } from 'lwc';
import { handleConfirmation, handleWarning, handleErrors, getModels } from 'c/einsteinUtils';

import deleteModel from '@salesforce/apex/Einstein_PlaygroundController.deleteModel';

export default class EinsteinDatasetDetailsLwc extends LightningElement {

	@api type;
	@api aiDataset;


	@track models;

	hasRendered = false;
	baseCompName = 'c-einstein-playground-base-lwc';
	selectedModelId;

	renderedCallback() {
		console.log('renderedCallback');

		if (!this.hasRendered) {
			this.hasRendered = true;

			this.onLoadModels();
		}
	}

	tooltip = false;

	showToolTip() {
		this.tooltip = true;
	}
	
    hideToolTip() {
		this.tooltip = false;
	}

	onLoadModels() {
		getModels(this.aiDataset.id, this.type)
		.then(result => {
			console.log('models received', result);
			// Hack so datasets are extensible
			this.models = JSON.parse(JSON.stringify(result));

			this.models.forEach(function (model) {
				model.ready = (model.status == 'SUCCEEDED');
				model.running = (model.status == 'RUNNING');
				model.failed = (model.status == 'FAILED');
				model.notRunningOrFailed = !(model.running || model.failed);
				model.progressPct = model.progress * 100;
			});
		})
		.catch(error => {
			handleErrors(error);
			console.log("Error: " + error.body);
		});
	}

	handleDeleteModelRequest(event) {
		this.selectedModelId = event.currentTarget.getAttribute('data-label');
		this.openDeleteConfirmationModal();
	}

	deleteModel() {
		this.closeModal();

		deleteModel({
			modelId: this.selectedModelId,
			dataType: this.type
		})
			.then(result => {
				handleConfirmation("Model " + this.selectedModelId + " deletion requested successfully");
			})
			.catch(error => {
				handleErrors(error);
		})

	}

	onPredict(event) {
		var selectedModelId = event.currentTarget.getAttribute('data-label');

		this.dispatchEvent(new CustomEvent('predict', {
			bubbles: true,
			composed: true,
			detail: {
				modelId: selectedModelId,
				datasetId: this.aiDataset.id
			}
		}));
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

	openDeleteConfirmationModal() {

		//find modal
		var modal = this.template.querySelector(".deleteConfirmationModal");
		var modalBackdrop = this.template.querySelector(".modal-Back");

		// Now add and remove class
		modal.classList.add("slds-fade-in-open");
		modalBackdrop.classList.add("slds-fade-in-open");
	}

	closeModal () {
		//find modal
		var modal = this.template.querySelector(".deleteConfirmationModal");
		var modalBackdrop = this.template.querySelector(".modal-Back");

		// Now add and remove class
		modal.classList.remove("slds-fade-in-open");
		modalBackdrop.classList.remove("slds-fade-in-open");
	}

	onCopyToClipboard(event) {

		let modelId = event.currentTarget.getAttribute('data-label');

		// Create an hidden input
		var hiddenInput = document.createElement("input");
		// passed text into the input
		hiddenInput.setAttribute("value", modelId);
		// Append the hiddenInput input to the body
		document.body.appendChild(hiddenInput);
		// select the content
		hiddenInput.select();
		// Execute the copy command
		document.execCommand("copy");
		// Remove the input from the body after copy text
		document.body.removeChild(hiddenInput); 
	}
}