({
  onLoadDatasets: function(component, event, helper) {
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

    if (dataType == "text-intent") {
      // See if feature code is enabled
      var self = this;
      var action = component.get("c.getFeatureCodeEnabled");
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === "ERROR") {
          var errors = response.getError();
          if (errors) {
            self.handleErrors(errors);
          } else {
            return console.log("Unknown error");
          }
        }
        if (response.getReturnValue()) {
          console.log("algorithmSelectEnabled: " + response.getReturnValue());
          component.set("v.algorithmSelectEnabled", true);
        }
      });
      $A.enqueueAction(action);
    }
  },

  getSelectedRow: function(component, event, helper) {
    var selectedDatasetId = event.getSource().get("v.name");
    var datasetList = component.get("v.datasets");

    for (var i = 0; i < datasetList.length; i++) {
      if (datasetList[i].id == selectedDatasetId) {
        component.set("v.selectedDataset", datasetList[i]);
      }
    }
  },

  messageHandler: function(component, event, helper) {
    console.log("heard new message");
    // Reload datasets if a new dataset was just created
    if (
      event.getParam("channel") === "EinsteinDatasetCreation" &&
      event.getParam("message") === "newDataset"
    ) {
      helper.onLoadDatasets(component);
    }
  },

  handleMenuSelect: function(component, event, helper) {
    var action = event.getParam("value");
    var selectedDatasetId = event.getSource().get("v.name");
    var datasetList = component.get("v.datasets");

    for (var i = 0; i < datasetList.length; i++) {
      if (datasetList[i].id == selectedDatasetId) {
        component.set("v.selectedDataset", datasetList[i]);
      }
    }

    var datasetCmp = component.find("cDataset");
    var algorithmSelectEnabled = component.get("v.algorithmSelectEnabled");

    if (action == "details") {
      datasetCmp.viewDetails();
    } else if (action == "train") {
      if (algorithmSelectEnabled) {
        component.set("v.isModalOpen", true);
      } else {
        datasetCmp.train();
      }
    } else if (action == "delete") {
      console.log("asking for delete...");
      datasetCmp.delete();
    }
  },

  closeModal: function(component, event, helper) {
    component.set("v.isModalOpen", false);
  },

  trainIntentV2Model: function(component, event, helper) {
    component.set("v.isModalOpen", false);
    var datasetCmp = component.find("cDataset");
    var selectedAlgorithm = component.get("v.selectedAlgorithm");
    datasetCmp.train(selectedAlgorithm);
  }
});
