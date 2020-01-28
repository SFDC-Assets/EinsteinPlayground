({
    // Invoked for both image and language predictions
    upload: function (component) {
        console.log("in the upload function");
        var dataType = component.get("v.dataType");
        var helper = this;

        component.set("v.markupPending", true);

        var action = this.actionBuilder(component);
        
        if (action==null) {
            console.log('Action could not be determined for this dataType');
            return;
        }
       	
        action.setParams(this.paramBuilder(component));

        action.setCallback(this, function (a) {
            // event.fire();
            
            if (a.getState() === "ERROR") {
                component.find("leh").passErrors(a.getError());
            }
            var result = a.getReturnValue();
            console.log("In action callback");
            console.log(result);

            // Sort OCR predictions for text or contact predictions.  Table predictions are already ordered
            var dataType = component.get("v.dataType");
            var ocrTask = component.get("v.ocrTask");
            if ((dataType == "ocr") && ((ocrTask == "text") || (ocrTask == "contact"))) {
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

            var rawProbabilities = JSON.stringify(result, null, 4);
            component.set("v.rawProbabilities", rawProbabilities);

            // if we got anything back
            if (result && result.probabilities.length) {
                //special handling for detection visualization
                if (dataType === 'image-detection' || dataType === 'ocr'){
                    var ro = new ResizeObserver(entries => {
                        this.generateSvg(component, result);
                    });

                    var img = component.find("imgItself").getElement();
                    ro.observe(img);
                    component.set("v.resizeObserver", ro);

                } 

                var probabilities = [];
                for (var i = 0; i < result.probabilities.length; i++) {
                    probabilities.push({
                        label: result.probabilities[i].label,
                        probability: result.probabilities[i].probability,
                        formattedProbability:
                            "" + Math.round(result.probabilities[i].probability * 100) + "%",
                        token: (result.probabilities[i].token ? result.probabilities[i].token : ""),
                        normalizedValue: (result.probabilities[i].normalizedValue ? result.probabilities[i].normalizedValue : ""),
                        boundingBox: (result.probabilities[i].boundingBox ? result.probabilities[i].boundingBox : ""),
                        attributes: (result.probabilities[i].attributes ? result.probabilities[i].attributes: "")
                    });
                }
                component.set("v.probabilities", probabilities);
            }
            helper.changeSpinner(component);
        });
        
        helper.changeSpinner(component);
        component.set("v.probabilities", null);
        component.set("v.rawProbabilities", null);
       // event.pause(); 
        $A.enqueueAction(action);
        
    },

    //decides what to do based on datatype
    actionBuilder : function(component) {
        var action;
        var dataType = component.get("v.dataType");
        const files = component.get("v.files");

        if (dataType === 'image' || dataType === 'image-multi-label') {
            if (files.length > 0 && files[0].length > 0){
                action = component.get("c.predictImageClassification");
            } else if (component.get("v.imageURL")){
                action = component.get("c.predictImageClassificationURL");
            }

        } else if (dataType === 'image-detection'){
            if (files.length > 0 && files[0].length > 0) {
                action = component.get("c.predictImageDetection");
            } else if (component.get("v.imageURL")) {
                action = component.get("c.predictImageDetectionURL");
            }

        } else if (dataType === 'ocr'){
            if (files.length > 0 && files[0].length > 0) {
                action = component.get("c.predictOcr");
            } else if (component.get("v.imageURL")) {
                action = component.get("c.predictOcrURL");
            }

        } else if (dataType === 'text-intent') {
            action = component.get("c.predictIntent");

        } else if (dataType === 'text-sentiment'){
            action = component.get("c.predictSentiment");

        } else if (dataType === 'text-ner'){
            action = component.get("c.predictNER");
        }
        return action;
    },

    paramBuilder : function(component) {
        var dataType = component.get("v.dataType");
        const files = component.get("v.files");
        var params = {
            modelId: component.get("v.modelId")
        };
        
        if (dataType === 'text-intent' || dataType === 'text-sentiment' || dataType === 'text-ner'){
            params.phrase = component.get("v.phrase");
        } else if (dataType === 'image' || dataType === 'image-multi-label' || dataType === 'image-detection' || dataType === 'ocr' ){
            if (files.length > 0 && files[0].length > 0) {
                params.base64 = component.get("v.pictureSrc").match(/,(.*)$/)[1];
            } else if (component.get("v.imageURL")) {
                params.url = component.get("v.pictureSrc");
            }
        }

        // Additional Task parameter for OCR
        if (dataType === 'ocr') {
            params.task = component.get("v.ocrTask");
        }

        return params;
    },



    // image detection and ocr stuff
    generateSvg: function (component, result) {
        console.log("generating svg");
        var helper = this;
        var dataType = component.get("v.dataType");

        var imgContainer = component.find("imgContainer").getElement();
        // Remove any existing DIVs from overlay 
        while (imgContainer.firstChild) {
            imgContainer.removeChild(imgContainer.firstChild);
        }

        var img = component.find("imgItself").getElement();
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

        var colors = this.buildColorCoding(probabilities);

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

            polygon.setAttribute("id", "polygon"+index);
            polygon.classList.add('polygon');
            polygon.onclick = function () {
                var index = this.id.substring(7);
            	helper.highlightOCRPredictions(component, index);
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

        component.set("v.markupPending", false);

        imgContainer.appendChild(svg);
    },

    
    // generates a palette of high-contrast colors
    buildColorCoding: function (probabilities) {
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
    },

    highlightOCRPredictions: function(component, index) {
        console.log('highlightOCRPredictions');
        var probabilities = component.get("v.probabilities");
        for (var i = 0; i < probabilities.length; i++) {
            var polygon = document.getElementById('polygon' + i);

            if (i == index) {
                console.log('Highlighting prediction '+ index);
                polygon.classList.add("polygonSelected");
                console.log(probabilities[i]);
                var selectedProbability = JSON.stringify(probabilities[i], null, 4);
                component.set("v.selectedProbability", probabilities[i]);
            } else {
                polygon.classList.remove('polygonSelected');
            }
        }
    },
    
    clearPredictions : function (component) {
        console.log('Clear all prediction data');

        // Stop observing changes to the image container so it doesn't freak out when the pictureSrc is cleared
        var ro = component.get("v.resizeObserver");
        if (ro) {
            console.log('disconnect');
            ro.disconnect();
        }

        // Remove any existing DIVs from overlay 
        var imgContainer = component.find("imgContainer");
        if (imgContainer) {
            var imgContainerEl = component.find("imgContainer").getElement();
            while (imgContainerEl.firstChild) {
                imgContainerEl.removeChild(imgContainerEl.firstChild);
            }
        }

        component.set("v.probabilities", null);
        component.set("v.selectedProbability", null);
        component.set("v.rawProbabilities", "");
        component.set("v.pictureSrc", "");

    }

})
