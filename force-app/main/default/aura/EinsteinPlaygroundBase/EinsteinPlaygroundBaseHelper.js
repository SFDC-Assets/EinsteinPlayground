({
    // Fetches all datasets of the type contained in the dataType attribute into the datasetList attribute
	loadAllDatasets: function (component) {
		console.log('EinsteinPlaygroundBaseHelper:loadAllDatasets');
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

    // Gets all models of the provided type and datasetId into the modelList attribute
    getModelsByDatasetId : function(component, datasetId, datasetType ) {
		console.log('EinsteinPlaygroundBaseHelper:getModelsByDatasetId');
        var self = this;       
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

    // Gets all modesl of the provided dataset.  Dataset contains the datasetId and datasetType
    getModelsByDataset: function(component, dataset) {
		console.log('EinsteinPlaygroundBaseHelper:getModelsByDataset');
        if (!dataset.available){
            return;
        }
        var datasetType = dataset.type;
        var datasetId = dataset.id;
        this.getModelsByDatasetId(component, datasetId, datasetType );   
    },

    isFeatureCodeEnabled: function(component, event) {
		console.log('EinsteinPlaygroundBaseHelper:isFeatureCodeEnabled');
        var self = this;
		var action = component.get("c.getFeatureCodeEnabled");
		action.setCallback(this, function(response) {
		  var state = response.getState();
		  if (state === "ERROR") {
			var errors = response.getError();
			if (errors) {
			   self.handleErrors(errors);
			} else {
			  return console.log("Unknown error");
			}
		  }
          console.log("isFeatureCodeEnabled: " + response.getReturnValue());
          if (response.getReturnValue()) {
	  		component.set("v.featureCodeEnabled", true);
          }
		});
        $A.enqueueAction(action);
    },

    changeSpinner: function(component) {
		console.log('EinsteinPlaygroundBaseHelper:changeSpinner');
    	var spinner = component.get("v.spinnerWaiting");
    	component.set("v.spinnerWaiting", !spinner);
    },

    handleErrors : function(errors) {
		console.log('EinsteinPlaygroundBaseHelper:handleErrors');        
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
            // Go figure, but some messages are a string object, not just a string,
            // for example, 
            // {"message":"There's currently a model for dataset 1172122 in a status of RUNNING or QUEUED. You must wait until that training process is complete before you can train the dataset again."}
            try {
                var message = JSON.parse(errors[0].message);
                toastParams.message = message.message;
            } catch(e) {
                toastParams.message = errors[0].message;
            }

            console.log(toastParams.message);
        }
        // Fire error toast
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
    },
    
    handleWarning : function(warning) {
		console.log('EinsteinPlaygroundBaseHelper:handleWarning');
        
        console.log( warning);
        
        // Configure error toast
        let toastParams = {
            title: "Warning!",
            message: warning,
            type: "warning"
        };
        // Fire warning toast
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
    },
    
    handleConfirmation : function( message) {
		console.log('EinsteinPlaygroundBaseHelper:handleConfirmation');
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