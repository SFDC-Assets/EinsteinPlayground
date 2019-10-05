({

	updateModelSelection: function (component, event) {
		var incoming = event.getParam("models");
		var dataType = event.getParam("type");
		console.log('--dataType-- ' + dataType);
		var models = component.get("v.modelsByType." + dataType) || [];

		for (var i = 0; i < incoming.length; i++) {
			if (incoming[i].progress == 1 && incoming[i].status === 'SUCCEEDED') { //that is, it's done training and worked
				models.push({ 
					id: incoming[i].modelId, 
					label: incoming[i].name ? incoming[i].name + ' ' + incoming[i].modelId : incoming[i].datasetId + " - " + incoming[i].modelId 
				});
			}
		}
        
        console.log('### models --- ' + models);

		component.set("v.modelsByType." + dataType, models);
	},

	enableTabs: function (component, event) {
		console.log('enableTabs');
		var self = this;
		var action = component.get("c.getSettings");
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
		  component.set("v.nerEnabled", response.getReturnValue().einsteinplay__NER_Enabled__c);
		  component.set("v.ocrEnabled", response.getReturnValue().einsteinplay__OCR_Enabled__c);
		});
		$A.enqueueAction(action);
	},

	handleErrors : function(errors) {
		$A.log("Errors",errors);
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
}  

});