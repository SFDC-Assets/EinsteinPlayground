({
    doInit : function(component, event, helper) {
        console.log("EinsteinPredictionAreaTestModelsController: doInit");
        // Default the modelId if ocr
        var dataType = component.get("v.dataType");
        if ( dataType == "ocr") {
            component.set("v.modelId", "OCRModel");
        }
    },

    // Set modelId according to the chosen OCR task
    ocrTaskChanged : function(component, event, helper) {
        console.log("EinsteinPredictionAreaTestModelsController: ocrTaskChanged");
        helper.clearPredictions(component);
        var ocrTask = component.get("v.ocrTask");
        console.log("ocrTask: " + ocrTask);

        switch (ocrTask) {
            case "text":
                component.set("v.modelId", "OCRModel");
                break;

            case "contact":
                component.set("v.modelId", "OCRModel");
                break;

            case "table":
                component.set("v.modelId", "tabulatev2");
                break;

            default:
                component.set("v.modelId", "");
        }
    },

    // Invoked when the user chooses an image file to upload using Upload Files
    readFile: function (component, event, helper) { 
        console.log("EinsteinPredictionAreaTestModelsController:readFile");
        helper.clearPredictions(component);
        var files = component.get("v.files");
        
        if (files && files.length > 0 && files[0] && files[0][0]) {
            
            helper.changeSpinner(component);
            var file = files[0][0];
            if (file.size > 5000000) {
                helper.changeSpinner(component);
                return alert("The file exceeds the limit of 5MB.");
            }
            var reader = new FileReader();
            reader.onloadend = function () {
                var dataURL = reader.result;
                component.set("v.imageURL", null);
                component.set("v.pictureSrc", dataURL);
                helper.upload(component);
                helper.changeSpinner(component);
               
            };
	        reader.readAsDataURL(file);
        }
    },

    // for text classification, OR when file/image is already present (and model changes)
    predict : function(component, event, helper) {
        console.log("EinsteinPredictionAreaTestModelsController:predict");
        var phrase = component.get("v.phrase");
        if(phrase == null || phrase.length == 0) {
            return;
        }
            
        var modelId = component.get("v.modelId");
        if(modelId != null && modelId.length > 0) {
            helper.upload(component);
        }
    },
    
    //for images from a URL
    predictURL : function(component, event, helper) {
        console.log("EinsteinPredictionAreaTestModelsController:predictURL");
        helper.clearPredictions(component);
        //set the imageURL for the photo
        component.set("v.files", []);
        component.set("v.pictureSrc", component.get("v.imageURL"));
    
        helper.upload(component);
    },
    
    // Used for OCR only.  
    ocrPolygonClicked : function(component, event, helper) {
        console.log('Polygon was clicked ');
        var polygonId = event.currentTarget.id;
        // Strip off the leading 'polygon' from id
        var index = polygonId.substring(7);

        helper.highlightOCRPredictions(component, index);
    },
    
})