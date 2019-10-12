({
    loadAllDatasets: function(component) {
        var self = this;
        var action = component.get("c.getDatasets");
        var dataType = component.get("v.dataType");
        action.setParams({
            dataType: dataType
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "ERROR") {
                var errors = response.getError();
                self.handleErrors(errors);
                
            }
            component.set("v.datasetList", response.getReturnValue());
          
        });

        $A.enqueueAction(action);
    },
      getModelsByDatasetId : function(component, datasetId, datasetType ) {
       
         var action = component.get("c.getModels");
          
        action.setParams({
            datasetId: datasetId,
            dataType: datasetType
        });
        action.setCallback(this, function(response) {
        
            var state = response.getState();
          
            if (state === "ERROR") {
                var errors = response.getError();
              
                self.handleErrors(errors);
            }
            //Need to handle null response if user clicks tab before
            //training an actual model
            var resp = response.getReturnValue();
            component.set("v.modelList",resp);
       
        });
     
        $A.enqueueAction(action);
    	
     },
  
    getModelsByDataset: function(component, dataset) {
        var action = component.get("c.getModels");
      //  var dataset = component.get("v.dataset");
        if (!dataset.available){
            return;
        }
        var datasetType = dataset.type;
        var datasetId = dataset.id;
      this.getModelsByDatasetId(component, datasetId, datasetType );
           
    },
  
    changeSpinner: function(component) {
    	var spinner = component.get("v.spinnerWaiting");
    	component.set("v.spinnerWaiting", !spinner);
  },
    handleErrors : function(errors) {
        
        for(var i=0; i<errors.length; i++) {
            console.log( errors[i]);
            console.log( errors[i].message);
        }
        
        // Configure error toast
        let toastParams = {
            title: "Error",
            message: "Unknown error", // Default error message
            type: "error"
        };
        // Pass the error message if any
        if (errors && Array.isArray(errors) && errors.length > 0) {
            toastParams.message = errors[0].message;
        }
        // Fire error toast
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
    },
    handleConfirmation : function( message) {
        // Configure error toast
        let toastParams = {
            title: "Confirmation",
            message: message, 
            type: "success"
        };
       
        // Fire error toast
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
    }
})