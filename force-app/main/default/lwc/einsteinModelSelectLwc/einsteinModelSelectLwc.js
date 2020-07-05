import { LightningElement, api } from 'lwc';
import { handleErrors, getDatasets, getModels } from 'c/einsteinUtils';

export default class EinsteinModelSelect extends LightningElement {
	@api type;

	selectedDatasetId;
	prebuilt;
	selectedModelId;
	datasetList;
	modelList;
	datasetOptions;
	modelOptions;

	connectedCallback() {
		console.log ('connectedCallback');
		getDatasets(this.type)
			.then(result => {
				console.log('datasets received by EinsteinModelSelect');
				this.prebuilt = true;
				this.datasetList = result;
				this.datasetOptions = this.getDatasetOptions();
			})
			.catch(error => {
				handleErrors(error);
				console.log("Error: " + error.body);
		});

	}

	datasetUpdated(event) {
		this.selectedDatasetId = event.detail.value;
		this.modelList = null;
		this.modelOptions = null;

		if (isNaN(Number(this.selectedDatasetId))) {
			this.prebuilt = true;
			this.selectedModelId = this.selectedDatasetId;
			this.notifyParent(this.selectedModelId);
		} else {
			this.prebuilt = false;
			this.selectedModelId = null;
			this.notifyParent(null);
			
			getModels(this.selectedDatasetId, this.type)
				.then(result => {
					this.modelList = result;
					this.modelOptions = this.getModelOptions();
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

	getDatasetOptions() {
		var options =[];

		// Add prebuilt models
		if (this.type == 'text-sentiment') {
			options.push({
				label: "Pre-Built - Sentiment",
				value: "CommunitySentiment"
			});
			// Default the selected Dataset in the combobox 
			this.selectedDatasetId = "CommunitySentiment";
			this.selectedModelId = 'CommunitySentiment';
			this.notifyParent('CommunitySentiment');
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
			options.push({
				label: "Pre-Built - OCR",
				value: "OCRModel"
			});
			// Default the selected Dataset in the combobox 
			this.selectedDatasetId = "OCRModel";
		}

		if (this.type == 'text-ner') {
			options.push({
				label: "Pre-Built - NER",
				value: "NER7"
			});
			// Default the selected Dataset in the combobox 
			this.selectedDatasetId = "NER7";
			this.selectedModelId = "NER7";
			this.notifyParent('NER7');
		}


		// Add custom datasets
		this.datasetList.forEach(element => {
			options.push({
				label: element.name,
				value: element.id.toString()
			});
		});

		return options;
	}

	getModelOptions() {
		if (!this.modelList) {
			return null;
		}

		var options = [];

		this.modelList.forEach(element => {
			options.push({
				label: element.modelId,
				value: element.modelId
			});
		});

		return options;
	}

	datasetListPopulated() {
		return (this.datasetList && this.datasetList.length > 0);
	}
}