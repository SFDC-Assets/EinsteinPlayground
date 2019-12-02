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
	}
})