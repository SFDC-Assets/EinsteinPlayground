import { LightningElement, track, api, wire } from 'lwc';
import { handleConfirmation, handleWarning, handleErrors, getDatasets, getFeatureCodeEnabled } from 'c/einsteinUtils';

import deleteDataset from '@salesforce/apex/Einstein_PlaygroundController.deleteDataset';
import trainDataset from '@salesforce/apex/Einstein_PlaygroundController.trainDataset';
import getMyUserId from '@salesforce/apex/Einstein_PlaygroundController.getMyUserId';
import writeCD from '@salesforce/apex/Einstein_PlaygroundController.writeCD';
import createDatasetFromUrl from '@salesforce/apex/Einstein_PlaygroundController.createDatasetFromUrl';

export default class EinsteinDatasetsAndModelsLwc extends LightningElement {


	@api type = "text-intent";

	@track datasets;

	hasRendered = false;
	baseCompName = 'c-einstein-playground-base-lwc';
	iconName;
	title;
	selectedDataset;
	selectedDatasetId;
	selectedAlgorithm = null;
	selectedAugment = false;
	selectedLanguage = "en_US";
	isFeatureCodeEnabled;
	fileUrl;
	filesAllowed;

	@track _myUserId;
	_error;

	@wire(getMyUserId)
	wiredGetMyUserId({ error, data }) {
		if (data) {
			console.log('getMyUserId returned data: ' + data);	
			this._myUserId = data
			this._error = undefined;
		
		} else if (error) {
			console.log('getMyUserId failed with: ' + JSON.stringify(error));
			handleErrors(error);
			this._error = error;
			this._myUserId = undefined;
		}
	}

	@api
    get myUserId() {
        return this._myUserId;
    }

    set myUserId(myUserId) {
        this._myUserId = myUserId;
    }


	renderedCallback() {
		console.log('renderedCallback');

		if (!this.hasRendered) {
			this.hasRendered = true;

			if (this.type === "image") {
				this.iconName = "standard:entitlement_template";
				this.title = "Image Classification";
				this.filesAllowed = ".zip";

			} else if (this.type === 'image-multi-label') {
				this.iconName = "utility:richtextbulletedlist";
				this.title = "Image Classification (Multi)"
				this.filesAllowed = ".zip";

			} else if (this.type === "image-detection") {
				this.iconName =  "standard:search";
				this.title =  "Object Detection";
				this.filesAllowed = ".zip";

			} else if (this.type === "text-sentiment") {
				this.iconName =  "standard:endorsement";
				this.title =  "Sentiment";
				this.filesAllowed = ".csv";

			} else if (this.type === "text-intent") {
				this.iconName = "standard:entitlement";
				this.title =  "Intent";
				this.filesAllowed = ".csv";

			} else {
				this.iconName =  "standard:survey";
			}
		
			getFeatureCodeEnabled() 
				.then(result => {
					this.isFeatureCodeEnabled = result;
				})
				.catch(error => {
					this.isFeatureCodeEnabled = false;
					handleErrors(error);
			})

			this.onLoadDatasets();
		}
	}

	get isIntentDataset() {
		return (this.type == 'text-intent');
	}

	get isImageDetection() {
		return (this.type == 'image-detection');
	}

	get isEmptyFileUrl() {
		return (!this.fileUrl);
	}


	get algorithmOptions() {
		var options =[];

		if (this.type == 'text-intent') {
			options.push({
				label: "Intent",
				value: "intent"
			});
			options.push({
				label: "Multilingual Intent",
				value: "multilingual-intent"
			});
			options.push({
				label: "Multilingual Intent OOD",
				value: "multilingual-intent-ood"
			});	
		} else if (this.type == 'image-detection') {
			options.push({
				label: "None",
				value: "none"
			});	
			options.push({
				label: "Decoupled Pilot",
				value: "decoupled-pilot"
			});	
		}

		return options;
	}

	algorithmUpdated(event) {
		this.selectedAlgorithm = event.detail.value;
	}

	augmentUpdated(event) {
		this.selectedAugment = event.target.checked;
	}

	onUrlInputChange(event) {
		this.fileUrl = event.target.value;
	}

	onCreateDataset() {
		console.log('create dataset');

		let self = this;

		var params = {
			url: this.fileUrl,
			dataType: this.type
		};

		if (this.type == 'text-intent') {
			params.language = this.selectedLanguage
		}

		createDatasetFromUrl(params)
			.then(result => {
				handleConfirmation("Dataset creation submitted successfully");
				this.onLoadDatasets();
			})
			.catch(error => {
				handleErrors(error);
		})
	}

	onLoadDatasets() {
		this.template.querySelector(this.baseCompName).setSpinnerWaiting(true);
		getDatasets(this.type)
		.then(result => {
			this.template.querySelector(this.baseCompName).setSpinnerWaiting(false);
			console.log('datasets received', result);
			// Hack so datasets are extensible
			this.datasets = JSON.parse(JSON.stringify(result));
		})
		.catch(error => {
			this.template.querySelector(this.baseCompName).setSpinnerWaiting(false);
			handleErrors(error);
			console.log("Error: " + error.body);
		});
	}

	handleLanguageValueChange(event) {
		this.selectedLanguage = event.detail.value;
	}

	handleUploadFinished(event) {
		console.log('handleUploadFinished');

		this.closeModal();

		var uploadedFiles = event.detail.files;
		var contentId = '';
		var filename = '';
		
		console.log("upload finished " + uploadedFiles.length);

		for (var i = 0; i < uploadedFiles.length; i++) {
			console.log(uploadedFiles[i].name + ' - ' + uploadedFiles[i].documentId);
			contentId = uploadedFiles[i].documentId;
			filename = uploadedFiles[i].name;
		}
		console.log("contentId is " + contentId);

		writeCD({
            contentDocumentId: contentId,
            name: filename
		})
			.then(result => {
				this.fileUrl = result.ContentDownloadUrl;
				this.onCreateDataset();
			})
			.catch(error => {
				handleErrors(error);
		})
	}

	toggleLabels(event) {
		let self = this;
		let datasetIndex = event.currentTarget.getAttribute('data-label');

		this.datasets.forEach(function (row, index) {
			if (row.labelsOpen && index != datasetIndex) {
				// you opened some other one, close this one
				row.labelsOpen = false;
			} else if (row.labelsOpen && index == datasetIndex) {
				// you're trying to toggle closed the currently open one
				row.labelsOpen = false;
			} else if (!row.labelsOpen && index == datasetIndex) {
				// it was closed and you're trying to open it
				row.labelsOpen = true;
			}
		});
	}

	toggleDetails(event) {
		let self = this;
		let datasetIndex = event.currentTarget.getAttribute('data-label');

		this.datasets.forEach(function (row, index) {
			if (row.open && index != datasetIndex) {
				// you opened some other one, close this one
				row.open = false;
			} else if (row.open && index == datasetIndex) {
				// you're trying to toggle closed the currently open one
				row.open = false;
			} else if (!row.open && index == datasetIndex) {
				// it was closed and you're trying to open it
				row.open = true;
			}
		});
	}

	handleMenuSelect(event) {
		let action = event.detail.value;
		this.selectedDatasetId = event.currentTarget.getAttribute('data-label');

		for (var i = 0; i < this.datasets.length; i++) {
			if (this.datasets[i].id == this.selectedDatasetId) {
				this.selectedDataset = this.datasets[i];
			}
		}

		if (action == "train") {
			if (this.type === "text-intent" ||
				(this.type === "image-detection" && this.isFeatureCodeEnabled)) {
				this.openTrainingModal();
			} else {
				this.onTrainDataset();
			}
		} else if (action == "delete") {
			this.onDeleteDataset();
		}
	
	}

	onTrainDataset() { 

		this.closeModal();

		trainDataset({
			datasetId: this.selectedDatasetId,
			modelName: this.selectedDataset.name + ' model',
			dataType: this.type,
			algorithm: (this.selectedAlgorithm == "none" ? null : this.selectedAlgorithm),
			augment: this.selectedAugment
		})
			.then(result => {
				handleConfirmation(
					"The model id for the training is " +
					result +
					". Refresh this view to see the training progress.");
			})
			.catch(error => {
				handleErrors(error);
		})
	}
	
	onDeleteDataset() {
		deleteDataset({
			datasetId: this.selectedDatasetId,
			dataType: this.type
		})
			.then(result => {
				handleConfirmation("Dataset " + this.selectedDatasetId + " deletion requested successfully");
				this.onLoadDatasets();
			})
			.catch(error => {
				handleErrors(error);
		})
	}

	openTrainingModal() {
		// Populate defaults
		if (this.type == 'text-intent') {
			this.selectedAlgorithm = "multilingual-intent";
		} else if (this.type == 'image-detection') {
			this.selectedAlgorithm = 'none';
		}

		//find modal
		var modal = this.template.querySelector(".trainingModal");
		var modalBackdrop = this.template.querySelector(".modal-Back");

		// Now add and remove class
		modal.classList.add("slds-fade-in-open");
		modalBackdrop.classList.add("slds-fade-in-open");
	}

	openCreateDatasetModal() {

		//find modal
		var modal = this.template.querySelector(".createDatasetModal");
		var modalBackdrop = this.template.querySelector(".modal-Back");

		// Now add and remove class
		modal.classList.add("slds-fade-in-open");
		modalBackdrop.classList.add("slds-fade-in-open");
	}

	closeModal () {
		//find modal
		var trainingModal = this.template.querySelector(".trainingModal");
		var createDatasetModal = this.template.querySelector(".createDatasetModal");
		var modalBackdrop = this.template.querySelector(".modal-Back");

		// Now add and remove class
		trainingModal.classList.remove("slds-fade-in-open");
		createDatasetModal.classList.remove("slds-fade-in-open");
		modalBackdrop.classList.remove("slds-fade-in-open");
	}

}