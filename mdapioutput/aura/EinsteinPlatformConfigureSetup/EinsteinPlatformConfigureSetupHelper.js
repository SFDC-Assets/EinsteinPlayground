({
    
     getEinsteinSettings : function(component) {
    	var action = component.get("c.getSettings");
 		var helper = this;
         
    	action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
             	var settings =  a.getReturnValue();
                component.set("v.settings",settings);
               
                if(settings.CacheName__c != null) {
                      component.set("v.enableCache",true);
                }
                
            } else if (a.getState() === "ERROR") {                
    			
                helper.handleErrors(a.getError());
            }
   		});

    	$A.enqueueAction(action);
     },
   
     getUserId : function(component) {
    	var action = component.get("c.getMyUserId");
 		var helper = this;
         
    	action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
             	var userId =  a.getReturnValue();
                component.set("v.userId",userId);
            } else if (a.getState() === "ERROR") {                
                helper.handleErrors(a.getError());
            }
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
})