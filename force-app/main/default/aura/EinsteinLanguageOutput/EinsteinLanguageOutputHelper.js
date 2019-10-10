({
	getModelId : function(component) {
		 let chosenModelId = component.get('v.modelId');
        
        if(chosenModelId == null) {
            let modelList = component.get('v.models');
            if(modelList == null || modelList.length == 0) {
                return;
            }
            chosenModelId = modelList[0].modelId;
            component.set('v.modelId', chosenModelId);
           
        }
        return chosenModelId;
	},
   handleErrors : function(errors) {
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