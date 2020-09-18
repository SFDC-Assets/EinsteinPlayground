import { LightningElement, api, track } from 'lwc';
import { handleErrors, getDatasets, getModels } from 'c/einsteinUtils';

export default class EinsteinModelSelect extends LightningElement {
	@api type;

	@track selectedDatasetId;
	@track selectedModelId;

	datasetOptions;
	modelOptions;

	_defaultDatasetId;
	_defaultModelId;

	@api
	get defaultDatasetId() {
		return this._defaultDatasetId;
	}

	set defaultDatasetId(value) {
		if (value) {
			// Cannot set combobox value until options have been populated
			if (this.datasetOptions) {
				this.datasetUpdated({ detail: {value: value.toString() }});
			} else {
				// Save.  connectedCallback will set after datasetOptions is populated
				this._defaultDatasetId = value.toString();
			}
		}
	}

	@api
	get defaultModelId() {
		return this._defaultModelId;
	}

	set defaultModelId(value) {
		if (value) {
			// Cannot set combobox value until options have been populated
			if (this.modelOptions) {
				this.modelUpdated({ detail: { value: value } });
			} else {
				this._defaultModelId = value;
			}
		}
	}

	connectedCallback() {
		console.log ('connectedCallback');
		getDatasets(this.type)
			.then(result => {
				console.log('datasets received by EinsteinModelSelect');
				this.getDatasetOptions(result);
				if (this._defaultDatasetId) {
					this.selectedDatasetId = this._defaultDatasetId;
				}
				this.datasetUpdated({ detail: { value: this.selectedDatasetId } });
			})
			.catch(error => {
				handleErrors(error);
				console.log("Error: " + error.body);
		});

	}

	renderedCallback() {
		console.log('renderedCallback');
	}

	datasetUpdated(event) {
		this.selectedDatasetId = event.detail.value;
		this.modelOptions = null;

		if (isNaN(Number(this.selectedDatasetId))) {
			//Pre-built models
			this.selectedModelId = this.selectedDatasetId;
			this.notifyParent(this.selectedModelId);
		} else {
			this.selectedModelId = null;
			this.notifyParent(null);
			
			getModels(this.selectedDatasetId, this.type)
				.then(result => {
					this.modelOptions = this.getModelOptions(result);
					if (this._defaultModelId) {
						this.selectedModelId = this._defaultModelId;
					}
					this.modelUpdated({ detail: { value: this.selectedModelId } });
				})
				.catch(error => {
					handleErrors(error);
			})
		}
		
	}

	modelUpdated(event) {
		console.log('model is ' + event.detail.value);
		this.notifyParent(event.detail.value);
	}

	notifyParent(value) {
		this.dispatchEvent(new CustomEvent('selected', {detail: value}));
	}

	getDatasetOptions(datasetList) {
		var options =[];

		// Add prebuilt models
		if (this.type == 'text-sentiment') {
			options.push({
				label: "Pre-Built - Sentiment",
				value: "CommunitySentiment"
			});
		}

		if (this.type == 'image') {
			options.push({
				label: "Pre-Built - General Image Classifier",
				value: "GeneralImageClassifier"
			});
			options.push({
				label: "Pre-Built - Food Image Classifier",
				value: "FoodImageClassifier"
			});
			options.push({
				label: "Pre-Built - Scene Image Classifier",
				value: "SceneClassifier"
			});
		}

		if (this.type == 'image-multi-label') {
			options.push({
				label: "Pre-Built - Multi-Label Image Classifier",
				value: "MultiLabelImageClassifier"
			});
		}

		if (this.type == 'ocr') {
			// Should never happen since ocr is handled by tasks in a parent
			options.push({
				label: "Pre-Built - OCR",
				value: "OCRModel"
			});
		}

		if (this.type == 'text-ner') {
			options.push({
				label: "Pre-Built - NER",
				value: "ENTITIES"
			});
		}


		// Add custom datasets
		datasetList.forEach(element => {
			options.push({
				label: element.name,
				value: element.id.toString()
			});
		});

		this.datasetOptions = options;

		// As a convienence, default the models for NER and sentiment
		if (this.type == 'text-sentiment') {
			this.selectedDatasetId = "CommunitySentiment";
			this.selectedModelId = 'CommunitySentiment';
			this.notifyParent('CommunitySentiment');
		}

		if (this.type == 'text-ner') {
			this.selectedDatasetId = "ENTITIES";
			this.selectedModelId = "ENTITIES";
			this.notifyParent('ENTITIES');
		}

	}

	getModelOptions(modelList) {
		if (!modelList) {
			return null;
		}

		var options = [];

		modelList.forEach(element => {
			options.push({
				label: element.modelId,
				value: element.modelId
			});
		});

		return options;
	}

}