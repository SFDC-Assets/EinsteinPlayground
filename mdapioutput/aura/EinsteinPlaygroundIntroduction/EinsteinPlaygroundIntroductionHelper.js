({
	 handleErrors : function(errors) {
         	$A.log("Errors",errors);
        // Configure error toast
        let toastParams = {
            title: "Error",
            message: "Unknown error", // Default error message
            mode: 'sticky', 
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
})