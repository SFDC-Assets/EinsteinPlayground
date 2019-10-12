({
    doInit : function(component, event, helper) {
        console.log ('EinsteinModelSelect doInit');
        console.log(component.get("v.allModels"));

        let dataType = component.get("v.dataType");
        let models = [];

        // Add any community models at the top of the list
        if (dataType === 'image'){
            models.push({ id: "GeneralImageClassifier", label: "Pre-Built - General Image Classifier" });
            models.push({ id: "FoodImageClassifier", label: "Pre-Built - Food Image Classifier" });
            models.push({ id: "SceneClassifier", label: "Pre-Built - Scene Image Classifier" });

        } else if (dataType === 'image-multi-label') {
            models.push({ id: "MultiLabelImageClassifier", label: "Pre-Built - Multi-Label Image Classifier" });

        } else if (dataType === 'ocr') {
            models.push({ id: "OCRModel", label: "Pre-Built - OCR" });

        } else if (dataType === 'text-sentiment'){
            models.push({ id: "CommunitySentiment", label: "Pre-Built - Community Sentiment" });

        } else if (dataType === 'text-ner') {
            models.push({ id: "NER7", label: "Pre-Built - NER" });
        }

        // add any custom models to the list if they exist
        if (component.get("v.allModels")[dataType] && component.get("v.allModels")[dataType].length>0){
            console.log('Adding custom models');
            models = models.concat(component.get("v.allModels")[dataType]);
        }

        // if there are any models, make the first one selected
        if (models.length>0){
            models[0].selected = true;
            component.set("v.modelId", models[0].id);
        }
        component.set("v.selectionModels", models);

    },

    valueChanged : function(component, event, helper) {
        console.log(component.find("selectModel").get("v.value"));
        component.set("v.modelId", component.find("selectModel").get("v.value"));
    },

})