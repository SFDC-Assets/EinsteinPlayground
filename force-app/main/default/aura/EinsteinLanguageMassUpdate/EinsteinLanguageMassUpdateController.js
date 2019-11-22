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

    getModels : function(component, event, helper) {
        var action = component.get("c.getModelList");
        var datasetId =  component.get("v.datasetId");
        
        if(datasetId == 'CommunitySentiment') {
             component.set("v.modelList", datasetId);
            return;
        }
        
        action.setParams({
            "datasetId": datasetId
        });
       
        action.setCallback(this, function(a){
          
            var state = a.getState();
            if (state === "SUCCESS") {
               
                component.set("v.modelList", a.getReturnValue());
            } else if (state === "ERROR") {
                $A.log("Errors", a.getError());
                helper.handleErrors(a.getError());
            }
        });
        $A.enqueueAction(action);
    },
    
    
	getFields : function(component, event, helper) {
         
       var action = component.get("c.getObjectFields");	
        
        
        component.set("v.objectsCompleted", 0);	
        
        let objName =  component.get("v.selectedObject");
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
     handleIntent : function(component, event, helper) {
		var startPos = 0;
        component.set("v.objectsCompleted", startPos);	
        console.log("Start " + startPos);
        var controller = "c.goClassify";
		helper.getIntent(component, event, startPos, controller, null);
        
	}
})