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
        
        console.log('### models --- ',  models);

		component.set("v.modelsByType." + dataType, models);
	},

	enableTabs: function (component, event) {
		var helper = this;
		console.log('enableTabs');
		var self = this;
		// method is in EinsteinPlaygroundBase 
		helper.isFeatureCodeEnabled(component, event);
	},

});