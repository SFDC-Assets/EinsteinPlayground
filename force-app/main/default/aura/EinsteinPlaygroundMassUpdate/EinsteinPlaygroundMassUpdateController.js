({
	doInit : function(component, event, helper) {
        var action = component.get("c.getObjectOptions");
    	action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
             	component.set("v.objects", a.getReturnValue());
                
            } else if (a.getState() === "ERROR") {                
    			$A.log("Errors", a.getError());
                helper.handleErrors(a.getError());
            }
   		});

    	$A.enqueueAction(action);
      
	},
 
	getFields : function(component, event, helper) {  
		component.set("v.objectsCompleted", 0);	
		component.set('v.selectedDestinationField1', '');
		component.set('v.selectedProbabilityField1', '');
		component.set('v.selectedDestinationField2', '');
		component.set('v.selectedProbabilityField2', '');
		component.set('v.selectedDestinationField3', '');
		component.set('v.selectedProbabilityField3', '');

        let objName =  component.get("v.selectedObject");
	   
		// Get the Source fields
		var action = component.get("c.getObjectFields");	        
		action.setParams({
			"objectName" : objName,
			"sourceOrLabel" : "Source"
		});
        
    	action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
             	component.set("v.sourceFields", a.getReturnValue());
            } else if (a.getState() === "ERROR") {                
                $A.log("Errors", a.getError());
                helper.handleErrors(a.getError());
            }
   		});
    	$A.enqueueAction(action);

		// Get the Label fields
		var action3 = component.get("c.getObjectFields");	        
		action3.setParams({
			"objectName" : objName,
			"sourceOrLabel" : "Label"
		});
        
    	action3.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
             	component.set("v.labelFields", a.getReturnValue());
            } else if (a.getState() === "ERROR") {                
                $A.log("Errors", a.getError());
                helper.handleErrors(a.getError());
            }
   		});
    	$A.enqueueAction(action3);

		// Get the Probability fields
		var action4 = component.get("c.getObjectFields");	        
		action4.setParams({
			"objectName" : objName,
			"sourceOrLabel" : "Probability"
		});
        
    	action4.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
             	component.set("v.probabilityFields", a.getReturnValue());
            } else if (a.getState() === "ERROR") {                
                $A.log("Errors", a.getError());
                helper.handleErrors(a.getError());
            }
   		});
    	$A.enqueueAction(action4);


		// Get the count of records for this object
        var action2 = component.get("c.getObjectCount");	
    	action2.setParams({
			"objectName" : objName
		}); 
        
    	action2.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
             component.set("v.objectCount", a.getReturnValue());
                
            } else if (a.getState() === "ERROR") {                
               
                $A.log("Errors", a.getError());
                helper.handleErrors(a.getError());
            }
   		});
    	$A.enqueueAction(action2);
    },
    
     handleClassify : function(component, event, helper) {
		var startPos = 0;
        component.set("v.objectsCompleted", startPos);	
        console.log("Start " + startPos);
        var controller = "c.goClassify";
		helper.getClassification(component, event, startPos, controller, null);
        
	}
})