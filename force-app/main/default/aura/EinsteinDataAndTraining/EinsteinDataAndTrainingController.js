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

    if (action == "details") {
      datasetCmp.viewDetails();
    } else if (action == "train") {
      datasetCmp.train();
    } else if (action == "delete") {
      console.log("asking for delete...");
      datasetCmp.delete();
    }
  }
});
