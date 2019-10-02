({
	doInit : function(component, event, helper) {
        console.log("Validating Settings...");
        
		var action = component.get("c.validateSetup");
 
    	action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
             	var connectionStatus =  a.getReturnValue();
                component.set("v.connectionStatus",connectionStatus);               
            } else if (a.getState() === "ERROR") {                
    			$A.log("Errors", a.getError());
                helper.handleErrors(a.getError());
            }
   		});

    	$A.enqueueAction(action);
	},
    showError : function(component, event, helper) {
        var showError = component.get("v.showError");
        showError = !showError;
         component.set("v.showError", showError);
    }
    
})