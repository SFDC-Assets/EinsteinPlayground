({
	onLoadDatasets: function (component, event, helper) {
		console.log('onLoadDatasets');
		helper.onLoadDatasets(component);

		// Set the icon and header based on the dataset type
		let dataType = component.get("v.dataType");
		if (dataType === "image") {
		component.set("v.iconName", "standard:entitlement_template");
		component.set("v.title", "Image");
		} else if (dataType === "text-intent") {
		component.set("v.iconName", "standard:entitlement");
		component.set("v.title", "Intent");
		} else if (dataType === "text-sentiment") {
		component.set("v.iconName", "standard:endorsement");
		component.set("v.title", "Sentiment");
		} else if (dataType === "image-detection") {
		component.set("v.iconName", "standard:search");
		component.set("v.title", "Object Detection");
		} else {
		component.set("v.iconName", "standard:survey");
		}

		// See if feature code is enabled in the base component
		// method is in EinsteinPlaygroundBase
		helper.isFeatureCodeEnabled(component, event);
  	},

  getSelectedRow: function (component, event, helper) {
	  console.log('getSelectedRow');
	  // getSource() only works for aura components.  Event now fired by td
	  	var selectedDatasetId = event.currentTarget.name;
    	var datasetList = component.get("v.datasets");

    	for (var i = 0; i < datasetList.length; i++) {
      		if (datasetList[i].id == selectedDatasetId) {
        		component.set("v.selectedDataset", datasetList[i]);
      		}
    	}
  },

	messageHandler: function(component, event, helper) {
		console.log("messageHandler");
		// Reload datasets if a new dataset was just created
		if (
			event.getParam("channel") === "EinsteinDatasetCreation" &&
			event.getParam("message") === "newDataset") {
			helper.onLoadDatasets(component);
		}
	},

	handleMenuSelect: function(component, event, helper) {
		var action = event.getParam("value");
		var selectedDatasetId = event.getSource().get("v.name");
		var datasetList = component.get("v.datasets");
		let dataType = component.get("v.dataType");
		var featureCodeEnabled = component.get("v.featureCodeEnabled");

		for (var i = 0; i < datasetList.length; i++) {
			if (datasetList[i].id == selectedDatasetId) {
				component.set("v.selectedDataset", datasetList[i]);
			}
		}

		var datasetCmp = component.find("cDataset");

		if (action == "details") {
			datasetCmp.viewDetails();
		} else if (action == "train") {
			if (dataType === "text-intent" ||
				(dataType === "image-detection" && featureCodeEnabled)) {
				helper.openModal(component, event);
			} else {
				datasetCmp.train();
			}
		} else if (action == "delete") {
			console.log("asking for delete...");
			datasetCmp.delete();
		}
	},

	closeModal: function(component, event, helper) {
		helper.closeModal(component, event);
	},

	trainPilotModel: function(component, event, helper) {
		helper.closeModal(component, event);
		var datasetCmp = component.find("cDataset");
		var selectedAlgorithm = component.get("v.selectedAlgorithm");
		var augment = component.get("v.augmentSelected");
		datasetCmp.train(selectedAlgorithm, augment);
	},

	onAugmentCheck: function(component, evt) {
		var checkCmp = component.find("augmentCheckbox");
		console.log("onAugmentCheck: " + checkCmp.get("v.value"));
		component.set("v.augmentSelected", "" + checkCmp.get("v.value"));
	}
});
