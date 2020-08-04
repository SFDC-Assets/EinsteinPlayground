import { LightningElement } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import LODASH from '@salesforce/resourceUrl/lodash';

import getObjectOptions from '@salesforce/apex/EinsteinLanguageMassUpdateController.getObjectOptions';
import getObjectFields from '@salesforce/apex/EinsteinLanguageMassUpdateController.getObjectFields';
import saveFileToFiles from '@salesforce/apex/Einstein_PlaygroundController.saveFileToFiles';
import writeCD from '@salesforce/apex/Einstein_PlaygroundController.writeCD';
import createDatasetFromUrl from '@salesforce/apex/Einstein_PlaygroundController.createDatasetFromUrl';
import { handleErrors, handleConfirmation } from 'c/einsteinUtils';
import { NavigationMixin } from 'lightning/navigation';

export default class EinsteinLanguageModelBuilderLwc extends NavigationMixin(LightningElement) {

	modelType;

	objects;
	sourceFields;
	classificationFields;

	selectedObject;
	selectedSourceField;
	selectedclassificationField;
	CV;

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

	getFields() {
		let self = this;
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
				self.classificationFields = result;
			})
			.catch(error => {
				handleErrors(error);
		})
	}
	get ready() {
		return (!this.CV && this.selectedSourceField && this.selectedclassificationField);
	}

	get modelTypeOptions() {
		var options = [];
		options.push({
			label: "Intent",
			value: "text-intent"
		});
		options.push({
			label: "Sentiment",
			value: "text-sentiment"
		});
		return options;
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

	get classificationFieldOptions() {
		if (!this.classificationFields) {
			return;
		}

		var options = [];
		this.classificationFields.forEach(element => {
			options.push({
				label: element,
				value: element
			});
		})
		return options;
	}

	handleModelTypeSelected(event) {
		this.modelType = event.detail.value;
	}

	handleObjectSelected(event) {
		this.selectedObject = event.detail.value;
		this.getFields();
	}

	handleSourceFieldSelected(event) {
		this.selectedSourceField = event.detail.value;
	}

	handleClassificationFieldSelected(event) {
		this.selectedclassificationField = event.detail.value;
	}

	createFile() {

		saveFileToFiles({
			obj: this.selectedObject,
			src: this.selectedSourceField,
			classify: this.selectedclassificationField
		})
			.then(result => {
				this.CV = result;
			})
			.catch(error => {
				handleErrors(error);
		})

	}

	viewFile() {

		let fileRef = {
			type: 'standard__namedPage',
			attributes: {
				pageName : 'filePreview'
			},
			state: {
				recordIds: this.CV.ContentDocumentId,
				selectedRecordId: this.CV.ContentDocumentId
			}
		};
		this[NavigationMixin.Navigate](fileRef);
	}

	createDataset() {
		writeCD({
			contentDocumentId: this.CV.ContentDocumentId,
			name: this.CV.Title
		})
			.then(result => {
				createDatasetFromUrl({
					url: result.ContentDownloadUrl,
					dataType : this.modelType
				})
					.then(result => {
						handleConfirmation("Dataset Created");
					})
					.catch(error => {
						handleErrors(error);
				})
			})
			.catch(error => {
				handleErrors(error);
		})
	}
}