({
    doInit : function(component, event, helper) {
        console.log ('EinsteinModelSelect doInit');

        // extended attribute from EinsteinPlaygroundBase
        var dataset= component.get("v.dataset");
        if(dataset == null) {
            helper.loadAllDatasets(component);
        } else {
            component.set("v.selectedDatasetId", dataset.id);

            // extended attribute from EinsteinPlaygroundBase
            var modelList= component.get("v.modelList");
            if(modelList != null && modelList.length > 0) {
                return;
            }

            helper.getModelsByDatasetId(component, dataset.id, dataset.type);
        }

    },

    datasetUpdated : function(component, event, helper) {
        var datasetId = component.get("v.selectedDatasetId");
        var dataType = component.get("v.dataType");

        if(isNaN(Number(datasetId))) {
            console.log("Selected String " + datasetId);
            component.set("v.modelId", datasetId);
            component.set("v.prebuilt", true);
            return;
        } else {
            component.set("v.prebuilt", false);
        }
        
        helper.getModelsByDatasetId(component, datasetId, dataType);
        
    },

})