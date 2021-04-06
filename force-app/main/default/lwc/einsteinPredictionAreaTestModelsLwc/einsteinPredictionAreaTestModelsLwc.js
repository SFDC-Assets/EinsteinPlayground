import { LightningElement, api, track} from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import RESIZE from '@salesforce/resourceUrl/resize';
import LODASH from '@salesforce/resourceUrl/lodash';
import PRETTIER from "@salesforce/resourceUrl/GoogleCodePrettify";

import { handleConfirmation, handleWarning, handleErrors, getFeatureCodeEnabled } from 'c/einsteinUtils';

import predictImageClassification from '@salesforce/apex/Einstein_PlaygroundController.predictImageClassification';
import predictImageClassificationURL from '@salesforce/apex/Einstein_PlaygroundController.predictImageClassificationURL';
import predictOcr from '@salesforce/apex/Einstein_PlaygroundController.predictOcr';
import predictOcrURL from '@salesforce/apex/Einstein_PlaygroundController.predictOcrURL';
import predictImageDetection from '@salesforce/apex/Einstein_PlaygroundController.predictImageDetection';
import predictImageDetectionURL from '@salesforce/apex/Einstein_PlaygroundController.predictImageDetectionURL';
import predictSentiment from '@salesforce/apex/Einstein_PlaygroundController.predictSentiment';
import predictIntent from '@salesforce/apex/Einstein_PlaygroundController.predictIntent';
import predictNER from '@salesforce/apex/Einstein_PlaygroundController.predictNER';

export default class EinsteinPredictionAreaTestModelsLwc extends LightningElement {
	@api type;
	@api iconName;

	@track ocrTask;
	@track ocrFormType;
	@track modelId;
	resizeObserver;
	probabilities = [];
	prettiedRawProbabilities;
	selectedProbability;
	pictureSrc = '';
	imageUrl;
	files;
	phrase;
	markupPending;
	isFeatureCodeEnabled;
	shelfData;

	shelfDataColumns = [
		{ label: "Label", fieldName: "label", type: "text" },
		{ label: "Count", fieldName: "count", type: "number" },
		{ label: "Share of Shelf", fieldName: "percentage", type: "percent" }
	];

	@track _defaultDatasetId;
	@track _defaultModelId;

	@api
	get defaultDatasetId() {
		return this._defaultDatasetId;
	}
	set defaultDatasetId(value) {
		this._defaultDatasetId = value;
	}

	@api
	get defaultModelId() {
		return this._defaultModelId;
	}
	set defaultModelId(value) {
		this._defaultModelId = value;
		this.modelId = value;
	}

	baseCompName = 'c-einstein-playground-base-lwc';
	hasRendered = false;

	renderedCallback() {
		console.log('renderedCallback');

		if (!this.hasRendered) {
			this.hasRendered = true;
			loadScript(this, RESIZE);
			loadScript(this, LODASH);

			Promise.all([
				loadScript(this, PRETTIER + "/google-code-prettify/prettify.js"),
				loadStyle(this, PRETTIER + "/google-code-prettify/prettify.css")
			  ])
				.then(() => {
				  PR.prettyPrint();
				})
				.catch((error) => {
				  console.log(error);
				});
		
			getFeatureCodeEnabled() 
				.then(result => {
					this.isFeatureCodeEnabled = result;
				})
				.catch(error => {
					this.isFeatureCodeEnabled = false;
					handleErrors(error);
			})
		}
	}


	get isOcrDataType() {
		return (this.type == 'ocr');
	}

	get isNerDataType() {
		return (this.type == 'text-ner');
	}

	get isVisionDataType() {
		return (this.type == 'image' || this.type == 'image-multi-label' || this.type == 'image-detection' || this.type == 'ocr');
	}

	get isObjectDetectionDataType() {
		return (this.type == 'image-detection');
	}

	get isNonBoundingBoxDataType() {
		return (this.type == 'image' || this.type == 'image-multi-label' || this.type == 'text-sentiment' || this.type == 'text-intent');
	}

	get isEmptyImageUrl() {
		return (!this.imageUrl);
	}

	get isOcrFormTask() {
		return (this.ocrTask == 'form');
	}

	get acceptTypes() {
		if (this.type == 'ocr') {
			return ".jpg,.JPEG,.png,.pdf";
		} else {
			return ".jpg,.JPEG,.png";
		}
	}

	get isPdf() {
		return ( (this.pictureSrc.toLowerCase().endsWith(".pdf")) ||
			     (this.pictureSrc.toLowerCase().startsWith("data:application/pdf")) );

	}

	get pdfClass() {
		if ( this.isPdf ) {
			return 'hidden';
		} else {
			return '';
		}
	}

	get activeResponseTab() {
		if ( this.isPdf ) {
		 	return "Tabular";
		} else {
			return "Formatted";
		}
	}

	get emptyPhrase() {
		return (!this.phrase);
	}
	
	get imgClass() {
		return this.markupPending ? 'picture transparent' : 'picture';
	}

	get afterClass() {
		return this.markupPending ? 'after slds-hidden' : 'after slds-visible';
	}

	get modelNotSelected() {
		switch (this.type) {
			case 'ocr':
				return (!this.ocrTask);
			default:
				return (!this.modelId);
		}
	}

	get ocrTaskOptions() {
		var options = [];
		options.push({
			label: "Text",
			value: "text"
		});
		options.push({
			label: "Contact",
			value: "contact"
		});
		options.push({
			label: "Table",
			value: "table"
		});

		if (this.isFeatureCodeEnabled) {
			options.push({
				label: "Form",
				value: "form"
			});	
		}

		return options;
	}

	get ocrFormTypeOptions() {
		var options = [];
		options.push({
			label: "dl",
			value: "dl"
		});
		options.push({
			label: "w2",
			value: "w2"
		});
		options.push({
			label: "permanentResident",
			value: "permanentResident"
		});
		options.push({
			label: "paystub",
			value: "paystub"
		});
		options.push({
			label: "1040",
			value: "1040"
		});
		options.push({
			label: "k1",
			value: "k1"
		});
		options.push({
			label: "passport",
			value: "passport"
		});

		return options;
	}

    // Set modelId according to the chosen OCR task
	ocrTaskChanged(event) {
        this.clearPredictions();
		this.ocrTask = event.detail.value;

        switch (this.ocrTask) {
            case "text":
			case "contact":
			case "form":
                this.modelId = "OCRModel";
                break;

            case "table":
                this.modelId = "tabulatev2";
                break;

			default:
				this.modelId = "";
        }

	}

	ocrFormTypeChanged(event) {
		this.clearPredictions();
		this.ocrFormType = event.detail.value;
	}

	onUrlInputChange(event) {
		this.imageUrl = event.target.value;
	}

	onPhraseChange(event) {
		this.phrase = event.target.value;
	}

	onModelSelected(event) {
		this.modelId = event.detail;
	}

	clearPredictions() {
        console.log('Clear all prediction data');

        // Stop observing changes to the image container so it doesn't freak out when the pictureSrc is cleared
        if (this.resizeObserver) {
            console.log('disconnect resizeObserver');
            this.resizeObserver.disconnect();
        }

        // Remove any existing DIVs from overlay 
        var imgContainer = this.template.querySelector(".picture");
        if (imgContainer) {
            while (imgContainer.firstChild) {
                imgContainer.removeChild(imgContainer.firstChild);
            }
        }

        this.probabilities = [];
        this.selectedProbability = null;
		this.setPrettifiedRawProbabilities('');
		this.pictureSrc = "";
		this.shelfData = null;
	}

	handleClick(event) {
		console.log('handleClick');
		
		this.clearPredictions();
		this.pictureSrc = this.imageUrl;
		this.upload(null);
	}

	onFileSelected(event) {
		var self = this;
		console.log('onFileSelected');
		var selectedFile = event.target.files[0];
		console.log("SelectedFile ", selectedFile);
		
		var reader = new FileReader();
		reader.onload = function (event) {
			self.pictureSrc = event.target.result;
		};
		this.readFile(selectedFile);
	}

	readFile(file) {
		console.log('readFile');
		self = this;
		if (!file) return;
		// if (!file.type.match(/(image.*)/)) {
		// 	return handleErrors({ message: "Image file not supported" });
		// }
		if (file.size > 50000000) {
			handleErrors("The file exceeds the limit of 5MB.");
			return;
		}

		this.clearPredictions();

		var reader = new FileReader();
		reader.onloadend = function () {
			self.fileName = file.name;
			var dataURL = reader.result;
			self.pictureSrc = dataURL;
			self.upload(file);
		};
		reader.readAsDataURL(file);
	}

	upload(file) {
		console.log('upload');
		self = this;
		this.markupPending = true;

		switch (this.type) {
			case 'image':
			case 'image-multi-label':
				this.template.querySelector(self.baseCompName).setSpinnerWaiting(true);
				if (file) {
					// File upload
					predictImageClassification({
						modelId: this.modelId,
						base64: this.pictureSrc.match(/,(.*)$/)[1]
					})
						.then(result => {
							self.processNonDetectionResult(result);
						})
						.catch(error => {
							self.template.querySelector(self.baseCompName).setSpinnerWaiting(false);
							handleErrors(error);
						})
				} else {
					// URL
					predictImageClassificationURL({
						modelId: this.modelId,
						url: this.pictureSrc
					})
						.then(result => {
							self.processNonDetectionResult(result);
						})
						.catch(error => {
							self.template.querySelector(self.baseCompName).setSpinnerWaiting(false);
							handleErrors(error);
						})
				}
				break;

			case 'image-detection':
				this.template.querySelector(self.baseCompName).setSpinnerWaiting(true);
				if (file) {
					// File upload
					predictImageDetection({
						modelId: this.modelId,
						base64: this.pictureSrc.match(/,(.*)$/)[1]
					})
						.then(result => {
							self.processDetectionResult(result);
						})
						.catch(error => {
							self.template.querySelector(self.baseCompName).setSpinnerWaiting(false);
							handleErrors(error);
						})
				} else {
					// URL
					predictImageDetectionURL({
						modelId: this.modelId,
						url: this.pictureSrc
					})
						.then(result => {
							self.processDetectionResult(result);
						})
						.catch(error => {
							self.template.querySelector(self.baseCompName).setSpinnerWaiting(false);
							handleErrors(error);
						})
				}
				break;

			case 'ocr':
				this.template.querySelector(self.baseCompName).setSpinnerWaiting(true);
				if (file) {
					// File upload
					var params = {
						modelId: this.modelId,
						base64: this.pictureSrc.match(/,(.*)$/)[1],
						task: this.ocrTask
					};

					if (this.ocrTask == 'form') {
						params.formType = this.ocrFormType;
					}

					predictOcr(params)
						.then(result => {
							self.processDetectionResult(result);
						})
						.catch(error => {
							self.template.querySelector(self.baseCompName).setSpinnerWaiting(false);
							handleErrors(error);
					})
				} else {
					// URL
					var params = {
						modelId: this.modelId,
						url: this.pictureSrc,
						task: this.ocrTask
					};

					if (this.ocrTask == 'form') {
						params.formType = this.ocrFormType;
					}

					predictOcrURL(params)
						.then(result => {
							self.processDetectionResult(result);
						})
						.catch(error => {
							self.template.querySelector(self.baseCompName).setSpinnerWaiting(false);
							handleErrors(error);
					})

				}
				break;
			
			case 'text-intent':
				predictIntent({
					modelId: this.modelId,
					phrase: this.phrase
				})
					.then(result => {
						self.processNonDetectionResult(result);
					})
					.catch(error => {
						self.template.querySelector(self.baseCompName).setSpinnerWaiting(false);
						handleErrors(error);
					})
				break;
				
			case 'text-sentiment':
				predictSentiment({
					modelId: this.modelId,
					phrase: this.phrase
				})
					.then(result => {
						self.processNonDetectionResult(result);
					})
					.catch(error => {
						self.template.querySelector(self.baseCompName).setSpinnerWaiting(false);
						handleErrors(error);
					})
				break;

			case 'text-ner':
				predictNER({
					modelId: this.modelId,
					phrase: this.phrase
				})
					.then(result => {
						self.processNonDetectionResult(result);
					})
					.catch(error => {
						self.template.querySelector(self.baseCompName).setSpinnerWaiting(false);
						handleErrors(error);
					})
				break;

			default:
				console.log('not yet implemented');
				break;
		}
		
	}

	processNonDetectionResult(result) {
		console.log('processImageClassificationResult', result);
		var probabilities = result.probabilities;
		self.template.querySelector(self.baseCompName).setSpinnerWaiting(false);

		self.setPrettifiedRawProbabilities(result);

		// if we got anything back
		if (result && result.probabilities.length) {
			self.probabilities = this.groomResults(probabilities, result);
		} else {
			self.probabilities = [];
		}
	}

	processDetectionResult(result) {
		console.log('processDetectionResult', result);

		// Sort OCR predictions for text or contact predictions.  Table predictions are already ordered
		if (self.type == 'ocr' && ((self.ocrTask == "text") || (self.ocrTask == "contact"))) {
			console.log("Sorting OCR");
			var probabilities = result.probabilities;
			probabilities.sort((a, b) => {
				var vertDiff = a.boundingBox.maxY - b.boundingBox.maxY;
				if (Math.abs(vertDiff) > 5) {
					return vertDiff;
				} else {
					return a.boundingBox.minX - b.boundingBox.minX;
				}
			});
			result.probabilities = probabilities;
		}

		self.setPrettifiedRawProbabilities(result);

		// if we got anything back
		if (result && result.probabilities.length) {
			if (this.type == "image-detection" || (this.type == "ocr" && !this.isPdf)) {
				//special handling for detection visualization
				self.resizeObserver = new ResizeObserver(entries => {
					self.generateSvg(result);
				});

				var img = self.template.querySelector('.picture');
				self.resizeObserver.observe(img);
			}

			self.probabilities = this.groomResults(probabilities, result);

			if (this.type == "image-detection") {
				this.calculateShelfData();
			}
		}
		self.template.querySelector(self.baseCompName).setSpinnerWaiting(false);

	}

	groomResults(probabilities, result) {
		var probabilities = [];
		for (var i = 0; i < result.probabilities.length; i++) {
			probabilities.push({
				index: i,
				label: result.probabilities[i].label,
				probability: result.probabilities[i].probability,
				formattedProbability: "" + Math.round(result.probabilities[i].probability * 100) + "%",
				token: (result.probabilities[i].token ? result.probabilities[i].token : ""),
				normalizedData: ((result.probabilities[i].normalizedData && result.probabilities[i].normalizedData[0]) ? result.probabilities[i].normalizedData[0] : ""),
				span: (result.probabilities[i].span ? result.probabilities[i].span : ""),
				boundingBox: (result.probabilities[i].boundingBox ? result.probabilities[i].boundingBox : ""),
				attributes: (result.probabilities[i].attributes ? result.probabilities[i].attributes : null)
			});
		}
		return probabilities;
	}

	calculateShelfData() {
		var calcObjects = {};
		var shelfData = [];
		var totalObjectCount = 0;

		// Create the list
		this.probabilities.forEach(function(probability) {
			totalObjectCount += 1;
			if (typeof calcObjects[probability.label] === "undefined") {
				var calcObject = {};
				calcObject.count = 1;
				calcObject.label = probability.label;
				calcObjects[probability.label] = calcObject;
			} else {
				calcObjects[probability.label].count += 1;
			}
		});

		// Add percentage
		Object.keys(calcObjects).forEach(function(label) {
			calcObjects[label].percentage = (calcObjects[label].count /
				totalObjectCount).toFixed(2);
			shelfData.push(calcObjects[label]);
		});
		
		this.shelfData = shelfData;
	}

	// image detection and ocr stuff
    generateSvg(result) {
        console.log("generateSvg");
        var self = this;
		var dataType = this.type;

        var imgContainer = self.template.querySelector('.after');
        // Remove any existing DIVs from overlay 
        while (imgContainer.firstChild) {
            imgContainer.removeChild(imgContainer.firstChild);
        }

        var img = self.template.querySelector('.picture');
        var proportion = img.clientHeight / img.naturalHeight;
        if (proportion > 1) {
            proportion = 1;
        }

        var probabilities = result.probabilities;

        var svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
        var svgNS = svg.namespaceURI;
        svg.classList.add('svg');

        var leftPos = img.offsetLeft;
        var topPos = img.offsetTop;

        var colors = self.buildColorCoding(probabilities);

        // Create transparent boxes for each label, positioned according to the
        // BoundingBox of the prediction
        probabilities.forEach(function (probability, index) {
            var color = colors[probability.label];
            // create polygon for box
            var polygon = document.createElementNS(svgNS, "polygon");
            polygon.setAttribute(
                "style",
                "stroke:" + color + ";"
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

            polygon.setAttribute("data-id", "polygon"+index);
            polygon.classList.add('polygon');
            polygon.onclick = function () {
                var index = this.getAttribute('data-id').substring(7);
            	self.highlightOCRPredictions(index);
            },this;

            svg.appendChild(polygon);

            if (dataType == 'image-detection') {
                // create text label near the polygon for each prediction
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
            }
        }, this);

        self.markupPending =false;

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

    highlightOCRPredictions (index) {
        console.log('highlightOCRPredictions');
		var probabilities = this.probabilities;
		for (var i = 0; i < probabilities.length; i++) {
			let query = '[data-id="polygon' + i + '"]';
            var polygon = this.template.querySelector(query);

            if (i == index) {
                console.log('Highlighting prediction '+ index);
                polygon.classList.add("polygonSelected");
                console.log(probabilities[i]);
                this.selectedProbability = probabilities[i];
            } else {
                polygon.classList.remove('polygonSelected');
            }
        }
    }
    

	analyse(base64Data) {
		console.log('analyse');
		this.template.querySelector(self.baseCompName).setSpinnerWaiting(true);

		detectObjects({
			base64: base64Data,
			modelId: this.modelId  
		})
		.then(result => {
			this.template.querySelector(self.baseCompName).setSpinnerWaiting(false);
			this.setPrettifiedRawProbabilities(result);
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

	predict() {
		console.log('predict');
        if(this.phrase == null || this.phrase.length == 0) {
            return;
		}
		this.upload(null);
	}

	setPrettifiedRawProbabilities(rawProbabilities) {
		// Use the Google Code Prettifier to pretty up the raw probabilities
		this.prettiedRawProbabilities = prettyPrintOne(JSON.stringify(rawProbabilities, null, 4));
	}

	onActive(event) {
		if (event.target.value == 'Raw') {
			this.setContent(this);
		}
	}

	setContent(self) {
		// The pre element on the raw tab has not been rendered to the DOM yet if this is the first
		// time the Raw tab has been opened.  Use requestAnimationFrame to retry until it exists.
		var myElement = self.template.querySelector('.prettyprint');
		if (!myElement) {
			window.requestAnimationFrame(() => { this.setContent(self) });
		} else {
			myElement.innerHTML = this.prettiedRawProbabilities;	
		}
	}

	onSelected (event) {
		console.log('onSelected');

		this.selectedProbability = this.probabilities[Number(event.detail)];
		console.log(this.selectedProbability);
	}
}