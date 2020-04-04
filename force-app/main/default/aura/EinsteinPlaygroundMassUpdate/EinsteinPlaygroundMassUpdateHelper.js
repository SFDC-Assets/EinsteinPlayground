({
    getClassification : function(component, event, startPos, controller, lastId) {
         var helper = this;  
		
         var BATCH_SIZE = 80;
         var END_POS = component.get("v.objectCount");
        
         if(startPos > END_POS) {
              return;
         }
         
         var modelId = component.get("v.selectedModel");
         
         var sourceName = component.get("v.selectedSourceField");
         var objectName = component.get("v.selectedObject");
         var dataType = component.get("v.dataType");
       
         var overwrite =  component.get("v.overwriteValues"); 
         var ignoreErrors = component.get("v.ignoreErrors"); 

        var endPos = startPos + BATCH_SIZE;
        console.log("Sending " + modelId + " " + sourceName + " " + objectName );  
        console.log("Moving to " + startPos + " " + endPos);   
        var action = component.get(controller);
      
        action.setParams({
            modelId : modelId,
            sourceName : sourceName,
            destinationName1 : component.get("v.selectedDestinationField1"),
            probabilityName1 : component.get("v.selectedProbabilityField1"),
            destinationName2 : component.get("v.selectedDestinationField2"),
            probabilityName2 : component.get("v.selectedProbabilityField2"),
            destinationName3 : component.get("v.selectedDestinationField3"),
            probabilityName3 : component.get("v.selectedProbabilityField3"),
            objectName : objectName,
            batchSize : BATCH_SIZE,
            overwriteValues: overwrite,
            latestId: lastId,
            ignoreErrors, ignoreErrors,
            dataType: dataType
        });
  
    	action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
                     
                startPos = endPos;
 
                var objectCount = component.get("v.objectCount");
                var objectsCompleted;
                if(startPos < objectCount)  {
                	objectsCompleted = startPos;
                } else {
                    objectsCompleted = objectCount;
                }
           		var progressPercent = objectsCompleted / objectCount * 100;
                
                 component.set("v.objectsCompleted", objectsCompleted);
                 component.set("v.progressPercent", progressPercent);
                
                let newLastId = a.getReturnValue();
                
                helper.getClassification(component, event, startPos, controller, newLastId);
                
            } else if (a.getState() === "ERROR") {                      
                $A.log("Errors", a.getError());
                this.handleErrors(a.getError());
            }
        //    helper.changeSpinner(component);
   		});

     //   helper.changeSpinner(component);
    	$A.enqueueAction(action);
        
    }
})