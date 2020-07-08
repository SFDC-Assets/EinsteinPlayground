import { LightningElement, api, track } from 'lwc';
import EINSTEIN_IMAGES from '@salesforce/resourceUrl/einstein_images';

import createRecord from '@salesforce/apex/Einstein_RecordVisionController.createRecord';
import postImageToChatter from '@salesforce/apex/Einstein_RecordVisionController.postImageToChatter';

import predictImageClassification from '@salesforce/apex/Einstein_PlaygroundController.predictImageClassification';
import writeCD from '@salesforce/apex/Einstein_PlaygroundController.writeCD';
import predictImageClassificationURL from '@salesforce/apex/Einstein_PlaygroundController.predictImageClassificationURL';

import { handleConfirmation, handleWarning, handleErrors } from 'c/einsteinUtils';

export default class EinsteinRecordImageClassification extends LightningElement {

	@api title;
	@api modelId;
	@api objectName;
	@api fieldName;
	@api attachImage;
	@api postToChatter = false;
  
	@api recordId;
  
	hasRendered = false;

	baseCompName = 'c-einstein-playground-base-lwc';
	platformCardName = 'c-einstein-platform-card-lwc';

	pictureSrc = EINSTEIN_IMAGES + '/einstein_images/EinsteinVIsionDefault.png';
	message = "Drag picture here";
	probability;
	prediction;
	attachId;
	meterWidth = 50;


	renderedCallback() {
		console.log('renderedCallback');

		if (!this.hasRendered) {
			this.hasRendered = true;
			this.template.querySelector(this.platformCardName).hasData = true;
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
		
		writeCD({
			contentDocumentId: contentId,
			name: filename
		})
		.then(result => {
			this.template.querySelector(this.baseCompName).setSpinnerWaiting(false);
			this.pictureSrc = result.ContentDownloadUrl;
			this.analyseUrl();
		})
		.catch(error => {
			handleErrors(error);
		});
	}
	
	analyseUrl() {
		console.log('analyseUrl');

		predictImageClassificationURL({
			modelId: this.modelId,
			url: this.pictureSrc
		})
		.then(result => {
			var probabilities = result.probabilities;
			this.prediction = probabilities[0].label;
			this.probability = probabilities[0].probability;
			this.meterWidth = Math.round(probabilities[0].probability * 100);

			if (this.postToChatter) {
				this.doPostToChatter(this.attachId);
			}
		})
		.catch(error => {
			handleErrors(error);
		});
	}

	doPostToChatter(contentId) {
		console.log('doPostToChatter');

		postImageToChatter({
			recordId: this.recordId,
			docId: contentId,
			comment: "Analyzed photo and found it to be " + this.prediction
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

	readFile(file) {
		self = this;
		if (!file) return;
		if (!file.type.match(/(image.*)/)) {
			return handleErrors({ message: "Image file not supported" });
		}
		var reader = new FileReader();
		reader.onloadend = function() {
			var dataURL = reader.result;
			self.pictureSrc = dataURL;
			self.analyse(dataURL.match(/,(.*)$/)[1]);
		};
		reader.readAsDataURL(file);
	}
	
	analyse (base64Data) {
		this.template.querySelector(this.baseCompName).setSpinnerWaiting(true);

		predictImageClassification({
			base64: base64Data,
			modelId: this.modelId  
		})
		.then(result => {
			this.template.querySelector(this.baseCompName).setSpinnerWaiting(false);
			var probabilities = result.probabilities;
			this.prediction = probabilities[0].label;
			this.probability = probabilities[0].probability;
			this.meterWidth = Math.round(probabilities[0].probability * 100);
		})
		.catch(error => {
			handleErrors(error);
		});
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

	handleClick() {
		console.log('handleClick');

		if (this.objectName == null || this.objectName.length == 0) {
			handleErrors({message: 'Configure Object Name component parameter in Lightning App Builder'});
			return;
		}
	  
		if (this.fieldName == null || this.fieldName.length == 0) {
			handleErrors({ message: 'Configure Field Name component parameter in Lightning App Builder' });
			return;
		}
	  
		createRecord({
			recordId: this.recordId,
			objectName: this.objectName,
			fieldName: this.fieldName,
			intentLabel: this.prediction
		})
		.then(result => {
			handleConfirmation("Einstein prediction saved successfully.");
		})
		.catch(error => {
			handleErrors(error);
		});
	}

}