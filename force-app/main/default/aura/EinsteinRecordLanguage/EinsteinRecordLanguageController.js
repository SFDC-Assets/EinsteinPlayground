({
	doInit : function(component, event, helper) {
        
        let action = component.get('c.getRecordAnalysis');
               
        action.setParams({
            recordId: component.get('v.recordId'),
            modelId:  component.get('v.modelId'),
            fieldName: component.get('v.fieldName')
        })
        action.setCallback(this, function(res){
            let state = res.getState();
            let retVal = res.getReturnValue();
       
            if(state === 'SUCCESS'){
              
                if(retVal){
                    component.set('v.predictionList', retVal);
                    component.set('v.hasData', true);
                }
            } else {
                console.log(res.getError());
            }
        })
        
        $A.enqueueAction(action);

        let action2 = component.get('c.getLanguagePhrase');               
        action2.setParams({
            recordId: component.get('v.recordId'),
            fieldName: component.get('v.fieldName')
        })
        action2.setCallback(this, function(res){
            console.log('getLanguagePhrase callback ' + res.getReturnValue);
            let state = res.getState();
            let retVal = res.getReturnValue();
       
            if(state === 'SUCCESS'){
              
                if(retVal){
                    component.set('v.intentPhrase', retVal);
                }
            } else {
                console.log(res.getError());
            }
        })
        
        $A.enqueueAction(action2);

    },
    savePrediction : function(component, event, helper) {
        
    	let action = component.get('c.savePredictionValue');
        
        let predictionList = component.get(' v.predictionList');
        let value = predictionList[0].label;
         console.log('Save Prediction ' + value);
        
        action.setParams({
            recordId: component.get('v.recordId'),
            value: value,
            fieldName: component.get('v.saveToField')
        })
        action.setCallback(this, function(res){
            let state = res.getState();
       
            if(state === 'SUCCESS'){
                helper.handleConfirmation("Einstein prediction saved successfully.");           
            } else {
                helper.handleErrors(res.getError());
            }
        })
        
        $A.enqueueAction(action);
        
    }
})