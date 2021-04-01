import { LightningElement, api, track } from 'lwc';
import { handleConfirmation, handleWarning, handleErrors } from 'c/einsteinUtils';

import getLearningCurves from '@salesforce/apex/Einstein_PlaygroundController.getLearningCurves';
import getModelMetrics from '@salesforce/apex/Einstein_PlaygroundController.getModelMetrics';

export default class EinsteinModelMetricsLwc extends LightningElement {

	@api type;
	@api aiDataset;
	@api modelId;

	metrics;
	@track LCdata;
	done;
	epoch;
	labelSummary = {};

	baseCompName = 'c-einstein-playground-base-lwc';
	hasRendered = false;

	get testAccuracy100() {
		return this.metrics.testAccuracy * 100;
	}

	get trainingAccuracy100() {
		return this.metrics.trainingAccuracy * 100;
	}

	get trainingLoss100() {
		return this.metrics.trainingLoss * 100;
	}

	get isUploading() {
		return (this.metrics.statusMsg == 'UPLOADING');
	}

	get header() {
		return 'Metrics for ' + this.aiDataset.name + ' / ' + this.modelId;
	}

	renderedCallback() {
		if (!this.hasRendered) {
			this.hasRendered = true;
			this.fetchModelMetrics();
		}
	}

	fetchModelMetrics() {
		let self = this;
		self.template.querySelector(self.baseCompName).setSpinnerWaiting(true);

		getModelMetrics({
			"modelId": this.modelId,
			"dataType": this.type
		})
			.then(result => {
				var self = this;

				this.metrics = JSON.parse(result);
				console.log("here are the model metrics:");
				console.log(this.metrics);
				console.log("here is the dataset label summary");
				console.log(JSON.parse(JSON.stringify(this.aiDataset.labelSummary.labels)));
				
				var newLabels = [];
				if (this.metrics.metricsData.labels) {
					this.metrics.metricsData.labels.forEach((metricsLabel, key) => {
						this.aiDataset.labelSummary.labels.forEach((datasetLabel, datasetkey) => {
							if (datasetLabel.name == metricsLabel) {
								newLabels.push({
									name: metricsLabel,
									id: datasetLabel.id,
									numExamples: datasetLabel.numExamples
								});
							}
						});
					});	
				} else if (this.metrics.metricsData.labelMetrics) {
					// Object Detection
					this.metrics.metricsData.labelMetrics.forEach((metricsLabel, key) => {
						this.aiDataset.labelSummary.labels.forEach((datasetLabel, datasetkey) => {
							if (datasetLabel.name == metricsLabel.label) {
								newLabels.push({
									name: metricsLabel.label,
									id: datasetLabel.id,
									numExamples: datasetLabel.numExamples
								});
							}
						});
					});	
				}
				this.labelSummary.labels = newLabels;

                //because there's not f1 in the metricsdata for object detection
				if (this.metrics.metricsData.f1) {
					this.metrics.metricsData.f1.forEach(function (f1, key) {
						self.labelSummary.labels[key].f1 = f1;
                    });
                }

                // ood datasets do not include a label for OOD, but the confusion matrix will
                // include an extra row and column for it.  Tack on another row here if necessary.
                // This assumes OOD is the last row, which I haven't confirmed as of 2/20/20.
                if ((this.type == "text-intent") && (this.metrics.algorithm == "multilingual-intent-ood")) {
                    if (this.labelSummary.labels.length = this.metrics.metricsData.labels.length) {
                        this.labelSummary.labels.push({
                          datasetId: this.aiDataset.id,
                          id: 0,
                          numExamples: null,
                          f1: null,
                          name: "OUT OF DOMAIN",
                          confusion: [],
                          confusionFormatted: []
                        });
                    }
                }

                if (this.metrics.metricsData.confusionMatrix) {
					// image, language
					this.metrics.metricsData.confusionMatrix.forEach(function (confusion, key) {
						self.labelSummary.labels[key].confusion = confusion;
						self.labelSummary.labels[key].confusionFormatted = self.formatConfusion(self.labelSummary.labels[key].name, confusion, self.metrics.metricsData.labels, []); 
                    });
                } else if (this.metrics.metricsData.confusionMatrices) {
                    // multi image
                    this.labelSummary.labels.forEach((datasetLabel, key) => {
                        datasetLabel.confusion = self.metrics.metricsData.confusionMatrices[datasetLabel.name];
                    });
                }

				getLearningCurves({
					modelId: this.modelId,
					dataType: this.type
				})
					.then(result => {
						let LCdata = JSON.parse(result).data;

						console.log("here are the original learning curves");
						console.log(LCdata);
	
						//transforamtions to tear out the array-style for multi-image
						if (this.type == 'image-multi-label') {
							LCdata = this.expandMultiImageLC(LCdata);
						}
	
						if (this.type == 'image-detection') {
							LCdata = this.formatDetectionData(LCdata);
						}
	
						if (!LCdata) {
							return; //we're done here
						}
	
						LCdata.forEach(function (epochRow) {
							epochRow.open = false;
							epochRow.labelData = [];
	
							//there's not labels for object detection, so we'll create them
							epochRow.metricsData.labels.forEach(function (label, key) {
								var thisData = {
									"name": label,
									"f1": epochRow.metricsData.f1[key]
								};
								if (epochRow.metricsData.confusionMatrix){
									thisData.confusionRaw = epochRow.metricsData.confusionMatrix[key];
								} else if (epochRow.metricsData.confusionMatrices){
									thisData.confusionRaw = epochRow.metricsData.confusionMatrices[thisData.name];
								}
								epochRow.labelData[key] = thisData;
								if (thisData.confusionRaw){
									//if there's any confusion, let's format it
									thisData.confusionFormatted = self.formatConfusion(label, thisData.confusionRaw, epochRow.metricsData.labels, epochRow.epochResults);
								}
	
							});
	
							// ood intent models don't include a label for ood, but do include it in confusion matrices
							// Add a phantom row here
							if ((self.type == "text-intent") && (self.metrics.algorithm == "multilingual-intent-ood")) {
								var numLabels = epochRow.metricsData.labels.length;
								epochRow.metricsData.labels.push ("OUT OF DOMAIN");
								var thisData = {
									label: "OUT OF DOMAIN",
									id: 0,
									f1: epochRow.metricsData.f1[numLabels-1],
									confusionRaw: epochRow.metricsData.confusionMatrix[numLabels-1]
								};
								epochRow.labelData[numLabels] = thisData;
								thisData.confusionFormatted = self.formatConfusion("OUT OF DOMAIN", thisData.confusionRaw, epochRow.metricsData.labels, epochRow.epochResults);
							}
	
						});
						
						this.LCdata = LCdata;
						if (this.type == 'image-multi-label') {
							// don't put the confusion matrix in the top section since it's postive/negative.  You can just pull it from the higheest epoch
						} else if (this.type == 'image-detection') {
							// put the f1 from the last epoch on the top-level model metrics
							self.labelSummary.labels.forEach((label, key) => {
								self.labelSummary.labels[key].f1 = LCdata[LCdata.length - 1].labelData[key].f1;
							});
						}
	
						console.log('Final labelSummary: ', this.labelSummary);
						console.log('Final LCdata: ', this.LCdata);
						self.done = true;

						self.template.querySelector(self.baseCompName).setSpinnerWaiting(false);
						
				})
					.catch(error => {
						self.template.querySelector(self.baseCompName).setSpinnerWaiting(false);
						handleErrors(error);
				});

			})
			.catch(error => {
				self.template.querySelector(self.baseCompName).setSpinnerWaiting(false);
				handleErrors(error);
				self.done = true;
			});
	}

	formatConfusion (label, confusionRaw, allLabels, results) {
        let output = [];

        confusionRaw.forEach(function (value, key){
            let outputMember = {
                key:key,
                value: value,
                isPrime: false,
                expected: label,
                predicted: allLabels[key],
                examples: []
			}
			
			// Account for out of domaain.  There will not be a final OUT OF DOMAIN
			// element in allLabels.
			if (key == allLabels.length) {
				outputMember.predicted = "OUT OF DOMAIN";
			}

            if (outputMember.expected === outputMember.predicted){
                outputMember.isPrime = true;
                outputMember.class = 'prime';
            } else {
                if (value > 0){
                    outputMember.class = 'bad';
                } else {
                    outputMember.class = 'good';
                }
            }

            //language models don't have a results object?
            if (results && results.length > 0) {
                results.forEach( (example) => {
                    if (example.expectedLabel === outputMember.expected && example.predictedLabel === outputMember.predicted){
                        outputMember.examples.push(example.exampleName);
                    }
                });
                outputMember.examplesString = outputMember.examples.join();
            }
            output.push(outputMember);
        });

        return output;
    }

    expandMultiImageLC (LCdata){
        let output = [];
        LCdata.forEach((LC)=>{
            LC.metricsData.labels.forEach((label,labelKey)=>{
                let LCnew = {
                    epoch: LC.epoch + '-' + label,
                    epochResults: LC.epochResults[label],
                    metricsData: {
                        confusionMatrix: LC.metricsData.confusionMatrices[label],
                        f1: LC.metricsData.f1[labelKey],
                        labels: [
                            label + "_positive",
                            label + "_negative"
                        ],
                        testAccuracy: LC.metricsData.testAccuracies[labelKey],
                        trainingAccuracy: LC.metricsData.trainingAccuracies[labelKey],
                        trainingLoss: null
                    }
                };
            output.push(LCnew);
            });
        });
        return output;
    }

    formatDetectionData (LCdata) {
        let output = [];
        LCdata.forEach((LC)=>{
            let LCnew = LC;
            LCnew.metricsData.f1 = [];
            LCnew.metricsData.labels = [];
            LC.metricsData.labelMetrics.forEach((lm, lmKey) => {
                LCnew.metricsData.f1.push(lm.f1);
                LCnew.metricsData.labels.push(lm.label);
                LCnew.metricsData.trainingLoss = LC.metricsData.modelMetrics.trainingLoss;
                LCnew.metricsData.testAccuracy = LC.metricsData.modelMetrics.meanAveragePrecision;
            });
            output.push(LCnew);
        });
        return output;
    }


	getEpochDetails(event) {
		let self = this;
		var epochIndex = event.currentTarget.getAttribute('data-label');
		
        //close all
        this.LCdata.forEach(function (row, index) {
            if (row.open && index != epochIndex) {
                // you opened some other one, close this one
                row.open = false;
            } else if (row.open && index == epochIndex) {
                // you're trying to toggle closed the currently open one
                row.open = false
            } else if (!row.open && index == epochIndex) {
                // it was closed and you're trying to open it
				row.open = true;
            }
        });
		
	}
}