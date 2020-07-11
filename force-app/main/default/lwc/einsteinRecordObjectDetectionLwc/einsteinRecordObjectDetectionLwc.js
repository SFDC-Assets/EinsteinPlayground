import { LightningElement, api } from 'lwc';
import EINSTEIN_IMAGES from '@salesforce/resourceUrl/einstein_images';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import RESIZE from '@salesforce/resourceUrl/resize';
import LODASH from '@salesforce/resourceUrl/lodash';

import postImageToChatter from '@salesforce/apex/Einstein_RecordVisionController.postImageToChatter';
import detectObjects from '@salesforce/apex/Einstein_RecordVisionController.detectObjects';
import createContentUrl from '@salesforce/apex/Einstein_RecordVisionController.createContentUrl';
import analyseImageUrl from '@salesforce/apex/Einstein_RecordVisionController.analyseImageUrl';
import storeScanResults from '@salesforce/apex/Einstein_RecordVisionController.storeScanResults';

import { handleConfirmation, handleWarning, handleErrors } from 'c/einsteinUtils';

export default class EinsteinRecordObjectDetectionLwc extends LightningElement {
	@api title;
	@api modelId;
	@api objectName;
	@api labelFieldName;
	@api countFieldName;
	@api attachImage;
	@api postToChatter = false;
  
	@api recordId;
  
	hasRendered = false;

	baseCompName = 'c-einstein-playground-base-lwc';
	platformCardName = 'c-einstein-platform-card-lwc';

	pictureSrc = EINSTEIN_IMAGES + '/einstein_images/EinsteinVIsionDefault.png';
	fileName;
	predictions;
	rawPredictions;
	showDatatable;
	shelfData;

	shelfDataColumns = [
		{ label: "Label", fieldName: "label", type: "text" },
		{ label: "Count", fieldName: "count", type: "number" },
		{ label: "Share of Shelf", fieldName: "percentage", type: "percent" }
	];

	renderedCallback() {
		console.log('renderedCallback');

		if (!this.hasRendered) {
			this.hasRendered = true;
			this.template.querySelector(this.platformCardName).hasData = true;
			loadScript(this, RESIZE);
			loadScript(this, LODASH);
		}
	}

	handleUploadFinished(event) {
		// Lightning-file-upload handler
		// Used if attachImage is true
		console.log('handleUploadFinished');

		var uploadedFiles = event.detail.files;
		var contentId = '';
		var filename = '';
		
		console.log("upload finished " + uploadedFiles.length);

		for (var i = 0; i < uploadedFiles.length; i++) {
			console.log(uploadedFiles[i].name + ' - ' + uploadedFiles[i].documentId);
			contentId = uploadedFiles[i].documentId;
			filename = uploadedFiles[i].name;
		}
		this.attachId = contentId;
		console.log("contentId is " + contentId);

		this.analyzeContent(contentId, filename);
	}

	analyzeContent(contentId, filename) {
		console.log('analyzeContent');
		this.template.querySelector(this.baseCompName).setSpinnerWaiting(true);
		
		createContentUrl({
			contentDocumentId: contentId
		})
		.then(result => {
			this.pictureSrc = result;
			this.analyseUrl();
		})
		.catch(error => {
			this.template.querySelector(this.baseCompName).setSpinnerWaiting(false);
			handleErrors(error);
		});
	}
	
	analyseUrl() {
		console.log('analyseUrl');

		analyseImageUrl({
			modelName: this.modelId,
			url: this.pictureSrc
		})
		.then(result => {
			this.template.querySelector(this.baseCompName).setSpinnerWaiting(false);
			this.rawPredictions = JSON.stringify(result, null, 4);
			this.predictions = result;

			var ro = new ResizeObserver(entries => {
				this.generateSvg();
			});
			var img = this.template.querySelector(".picture");
			ro.observe(img);
			this.calculateShelfData();
			this.showDatatable = true;

			if (this.postToChatter) {
				this.doPostToChatter(this.attachId);
			}
		})
		.catch(error => {
			this.template.querySelector(this.baseCompName).setSpinnerWaiting(false);
			handleErrors(error);
		});
	}

	doPostToChatter(contentId) {
		console.log('doPostToChatter');

		postImageToChatter({
			recordId: this.recordId,
			docId: contentId,
			comment: "Analyzed photo."
		})
		.then(result => {
			handleConfirmation('Image posted to Chatter');
		})
		.catch(error => {
			handleErrors(error);
		});
	}		
		



	onFileSelected(event) {
		// input type='"file" handler.
		//Used if attachImage is false
		var self = this;
		console.log('onFileSelected');
		var selectedFile = event.target.files[0];
		console.log("SelectedFile ", selectedFile);
		
		var reader = new FileReader();
		reader.onload = function (event) {
			self.pictureSrc = event.target.result;
		};
		this.probability = 0;
		this.readFile(selectedFile);
	}



	onDragOver(event) {
		console.log('onDragOver');
		event.preventDefault();
	}

	onDrop(event) {
		console.log('onDrop');
		event.stopPropagation();
		event.preventDefault();
		event.dataTransfer.dropEffect = 'copy';
		var files = event.dataTransfer.files;
		console.log('files: ', files[0]);
		if (files.length > 1) {
			return handleErrors({ message: "You can only analyse one picture at a time" });
		}
		if (files[0].size > 5000000) {
			return handleErrors({ message: "The file exceeds the limit of 5MB." });
		}
		this.probability = 0;
		this.readFile(files[0]);

	}

	readFile(file) {
		self = this;
		if (!file) return;
		if (!file.type.match(/(image.*)/)) {
			return handleErrors({ message: "Image file not supported" });
		}
		var reader = new FileReader();
		reader.onloadend = function () {
			self.fileName = file.name;
			var dataURL = reader.result;
			self.pictureSrc = dataURL;
			self.analyse(dataURL.match(/,(.*)$/)[1]);
		};
		reader.readAsDataURL(file);
	}
	
	analyse(base64Data) {
		console.log('analyse');
		this.template.querySelector(this.baseCompName).setSpinnerWaiting(true);

		detectObjects({
			base64: base64Data,
			modelId: this.modelId  
		})
		.then(result => {
			this.template.querySelector(this.baseCompName).setSpinnerWaiting(false);
			this.rawPredictions = JSON.stringify(result, null, 4);
			this.predictions = result;

			var ro = new ResizeObserver(entries => {
				this.generateSvg();
			  });
			  var img = this.template.querySelector(".picture");
			  ro.observe(img);
			  this.calculateShelfData();
			  this.showDatatable = true;
		})
		.catch(error => {
			handleErrors(error);
		});
	  }

	calculateShelfData() {
		console.log('calculateShelfData');
		var probabilities = this.predictions.probabilities;
		var calcObjects = {};
		var shelfData = [];
		var allObjects = 0;

		probabilities.forEach(function(probability) {
			allObjects += 1;
			if (typeof calcObjects[probability.label] === "undefined") {
				var calcObject = {};
				calcObject.count = 1;
				calcObject.label = probability.label;
				calcObjects[probability.label] = calcObject;
			} else {
				calcObjects[probability.label].count += 1;
			}
		});

		Object.keys(calcObjects).forEach(function(label) {
			calcObjects[label].percentage = (
				calcObjects[label].count / allObjects
		  	).toFixed(2);
			shelfData.push(calcObjects[label]);
		});
		this.shelfData = shelfData;
	
	}

	generateSvg() {
		console.log('generateSvg');
		var imgContainer = this.template.querySelector(".after");
		// Remove any existing DIVs from overlay 
		while (imgContainer.firstChild) {
			imgContainer.removeChild(imgContainer.firstChild);
		}
		var img = this.template.querySelector(".picture");
	
		var proportion = img.clientHeight / img.naturalHeight;
		if (proportion > 1) {
			proportion = 1;
		}
	
		var predictions = this.predictions;
		if (predictions == null) {
			return;
		}
	
		var probabilities = predictions.probabilities;
	
		var svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
		var svgNS = svg.namespaceURI;
		svg.setAttribute(
			"style",
			"width: 100%; height: 100%;"
		);
	
		var leftPos = img.offsetLeft;
		var topPos = img.offsetTop;
	
		var colors = this.buildColorCoding(probabilities);
	
		probabilities.forEach(function(probability) {
			var color = colors[probability.label];
			// create polygon for box
			var polygon = document.createElementNS(svgNS, "polygon");
			polygon.setAttribute(
				"style",
				"stroke:" + color + ";" +
				"stroke-width:3;" +
				"fill-opacity:0;"
			);
			var points = [];
			points.push(
				(probability.boundingBox.minX * proportion + leftPos) +
				"," +
				(probability.boundingBox.minY * proportion + topPos)
			);
			points.push(
				(probability.boundingBox.maxX * proportion + leftPos) +
				"," +
				(probability.boundingBox.minY * proportion + topPos)
			);
			points.push(
				(probability.boundingBox.maxX * proportion + leftPos) +
				"," +
				(probability.boundingBox.maxY * proportion + topPos)
			);
			points.push(
				(probability.boundingBox.minX * proportion + leftPos) +
				"," +
				(probability.boundingBox.maxY * proportion + topPos)
			);
			polygon.setAttribute("points", points.join(" "));
			polygon.classList.add('polygon');
		
			svg.appendChild(polygon);
	
			// create text box
			var div = document.createElement("div");
			div.setAttribute(
				"style",
				"position:absolute;top:" +
				  probability.boundingBox.maxY * proportion +
				  "px;left:" +
				  (probability.boundingBox.minX * proportion + leftPos) +
				  "px;width:" +
				  (probability.boundingBox.maxX - probability.boundingBox.minX) *
					proportion +
				  "px;text-align:center;color:" +
				  color +
				  ";"
			);
			div.innerHTML = probability.label;
		  	imgContainer.appendChild(div);
		}, this);
		
		imgContainer.appendChild(svg);
	}

	// generates a palette of high-contrast colors
	buildColorCoding (probabilities) {
		var colors = {};
		var uniqueLabels = _.uniq(_.map(probabilities, 'label'));
  
		var colorArray = [
			'#e6194b',
			'#3cb44b',
			'#ffe119',
			'#0082c8',
			'#f58231',
			'#911eb4',
			'#46f0f0',
			'#f032e6',
			'#d2f53c',
			'#fabebe',
			'#008080',
			'#e6beff',
			'#aa6e28',
			'#fffac8',
			'#800000',
			'#aaffc3',
			'#808000',
			'#ffd8b1',
			'#000080',
			'#808080',
			'#FFFFFF',
			'#000000'
		]
  
		for (var i = 0; i < uniqueLabels.length; i++) {
			// OCR could return more labels than this list of colors,
			// so wrap around and reuse, if necessary
			colors[uniqueLabels[i]] = colorArray[i % colorArray.length];
		}
		return colors;
	}
  
	addItemsToRecords(event) {
		console.log('addItemsToRecords');
		let self = this;

		if (this.objectName == null || this.objectName.length == 0) {
			console.log("objectName null");
			return;
		}
	  
		if (
			(this.labelFieldName == null || this.labelFieldName.length == 0) &&
			(this.countFieldName == null || this.countFieldName.length == 0))
		{
			console.log("Fields null");
			return;
		}

		var value;

		this.shelfData.forEach(function (item) {
			value = '{"sobjectType":"' + self.objectName + '"';
			
			if (self.labelFieldName != null && self.labelFieldName.length >= 0) {
				value = value + ',"' + self.labelFieldName + '": "' + item.label + '"';
			}
			
			if (self.countFieldName != null && self.countFieldName.length >= 0) {
				value = value + ',"' + self.countFieldName + '": "' + item.count + '"';
			}
			
			value = value + "} ";
			console.log(value);

			storeScanResults({
				dataJson: value,
				recordId: self.recordId,
				objectName: self.objectName
			})
				.then(result => {
					handleConfirmation("Einstein prediction saved successfully");
				})
				.catch(error => {
					handleErrors(error);
			})
		})
	}
}