import { LightningElement, api, track } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import LODASH from '@salesforce/resourceUrl/lodash';

import { handleConfirmation, handleWarning, handleErrors } from 'c/einsteinUtils';

import getObjectOptions from '@salesforce/apex/EinsteinLanguageMassUpdateController.getObjectOptions';
import getObjectFields from '@salesforce/apex/EinsteinLanguageMassUpdateController.getObjectFields';
import getObjectCount from '@salesforce/apex/EinsteinLanguageMassUpdateController.getObjectCount';
import goClassify from '@salesforce/apex/EinsteinLanguageMassUpdateController.goClassify';

export default class EinsteinPlaygroundMassUpdateLwc extends LightningElement {

	@api type;

	objects;
	overwriteValues = false;
	ignoreErrors = false;
	modelId;
	selectedObject;
	objectsCompleted;	
	selectedSourceField;
	selectedDestinationField1;
	selectedProbabilityField1;
	selectedDestinationField2;
	selectedProbabilityField2;
	selectedDestinationField3;
	selectedProbabilityField3;
	sourceFields;
	labelFields;
	probabilityFields;
	objectCount;
	objectsCompleted;
	progressPercent;

	baseCompName = 'c-einstein-playground-base-lwc';

	hasRendered = false;
	renderedCallback() {
		console.log('renderedCallback');

		if (!this.hasRendered) {
			this.hasRendered = true;
			loadScript(this, LODASH);
			this.getObjects();
		}
	}

	getObjects() {
		console.log('get objects');
		getObjectOptions()
			.then(result => {
				this.objects = result;
			})
			.catch(error => {
				handleErrors(error);
		})
	}

	get objectOptions() {
		if (!this.objects) {
			return;
		}

		var options = [];
		this.objects.forEach(element => {
			options.push({
				label: element,
				value: element
			});
		})
		return options;
	}

	get sourceFieldOptions() {
		if (!this.sourceFields) {
			return;
		}
		
		var options = [];
		this.sourceFields.forEach(element => {
			options.push({
				label: element,
				value: element
			});
		})
		return options;
	}

	get labelFieldOptions() {
		if (!this.labelFields) {
			return;
		}
		
		var options = [];
		this.labelFields.forEach(element => {
			options.push({
				label: element,
				value: element
			});
		})
		return options;
	}

	get probabilityFieldOptions() {
		if (!this.probabilityFields) {
			return;
		}

		var options = [];
		this.probabilityFields.forEach(element => {
			options.push({
				label: element,
				value: element
			});
		})
		return options;
	}

	get sourceFieldLabel() {
		if (this.type == "image") {
			return "Which text field contains the URL to the image you want to classify?";
		}

		return "What text field do you want to classify?"
	}

	handleOverwriteChange(event) {
		this.overwriteValues = event.target.checked;
	}

	handleIngoreErrorsChange(event) {
		this.ignoreErrors = event.target.checked;
	}

	handleObjectSelected(event) {
		this.selectedObject = event.detail.value;
		this.getFields();
	}

	handleSourceFieldChange(event) {
		this.selectedSourceField = event.detail.value;
	}

	handleLabelFieldChange(event) {
		console.log('handleLabelFieldChange', event.target.name);
		switch (event.target.name) {
			case 'sourceField1Select':
				this.selectedDestinationField1 = event.detail.value;
				break;
		
			case 'sourceField2Select':
				this.selectedDestinationField2 = event.detail.value;
				break;
			
			case 'sourceField3Select':
				this.selectedDestinationField3 = event.detail.value;
				break;
				
			default:
				break;
		}
	}

	handleProbabilityFieldChange(event) {
		console.log('handleProbabilityFieldChange', event.target.name);
		switch (event.target.name) {
			case 'probabilityField1Select':
				this.selectedProbabilityField1 = event.detail.value;
				break;
		
			case 'probabilityField2Select':
				this.selectedProbabilityField2 = event.detail.value;
				break;
			
			case 'probabilityField3Select':
				this.selectedProbabilityField3 = event.detail.value;
				break;
				
			default:
				break;
		}
	}

	onModelSelected(event) {
		this.modelId = event.detail;
	}

	getFields() {
		let self = this;
		this.objectsCompleted = '';	
		this.selectedDestinationField1 = '';
		this.selectedProbabilityField1 = '';
		this.selectedDestinationField2 = '';
		this.selectedProbabilityField2 = '';
		this.selectedDestinationField3 = '';
		this.selectedProbabilityField3 = '';

		getObjectFields({
			objectName: this.selectedObject,
			sourceOrLabel: "Source"
		})
			.then(result => {
				self.sourceFields = result;
			})
			.catch(error => {
				handleErrors(error);
		})

		getObjectFields({
			objectName: this.selectedObject,
			sourceOrLabel: "Label"
		})
			.then(result => {
				self.labelFields = result;
			})
			.catch(error => {
				handleErrors(error);
		})
	
		getObjectFields({
			objectName: this.selectedObject,
			sourceOrLabel: "Probability"
		})
			.then(result => {
				self.probabilityFields = result;
			})
			.catch(error => {
				handleErrors(error);
		})

		getObjectCount({
			objectName: this.selectedObject
		})
			.then(result => {
				self.objectCount = result;
			})
			.catch(error => {
				handleErrors(error);
		})
	}

	handleClassify() {
		var startPos = 0;
		this.objectsCompleted = startPos;
		console.log('Start ' + startPos);

		var lastId;
		this.getClassification(startPos, lastId);

	}

	getClassification(startPos, lastId) {
		let BATCH_SIZE = 80;
		let END_POS = this.objectCount;

		if (startPos > END_POS) {
			return;
		}

		var endPos = startPos + BATCH_SIZE;

		console.log("Sending " + this.modelId + " " + this.selectedSourceField + " " + this.selectedObject);
		console.log("Moving to " + startPos + " " + endPos);

		goClassify({
			modelId : this.modelId,
            sourceName : this.selectedSourceField,
            destinationName1 : this.selectedDestinationField1,
            probabilityName1 : this.selectedProbabilityField1,
            destinationName2 : this.selectedDestinationField2,
            probabilityName2 : this.selectedProbabilityField2,
            destinationName3 : this.selectedDestinationField3,
            probabilityName3 : this.selectedProbabilityField3,
            objectName : this.selectedObject,
            batchSize : BATCH_SIZE,
            overwriteValues: this.overwriteValues,
            latestId: lastId,
            ignoreErrors: this.ignoreErrors,
            dataType: this.type
		})
			.then(result => {
				startPos = endPos;

				if (startPos < this.objectCount) {
					this.objectsCompleted = startPos;
				} else {
					this.objectsCompleted = this.objectCount;
				}

				this.progressPercent = this.objectsCompleted / this.objectsCount * 100;

				let newLastId = result;

				this.getClassification(startPos, newLastId);

			})
			.catch (error => {
				handleErrors(error);					
			})
	}
	

}