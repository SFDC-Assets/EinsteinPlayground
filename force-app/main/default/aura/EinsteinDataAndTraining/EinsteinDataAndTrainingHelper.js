({
  onLoadDatasets: function(component) {
    var self = this;
    var action = component.get("c.getDatasets");
    var dataType = component.get("v.dataType");
    action.setParams({
      dataType: dataType
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === "ERROR") {
        var errors = response.getError();
        self.handleErrors(response.getError());
        if (errors) {
        } else {
          return console.log("Unknown error");
        }
      }
      component.set("v.datasets", response.getReturnValue());
      var event = component.getEvent("waitingEvent");
      event.fire();
    });
    var event = component.getEvent("waitingEvent");
    event.fire();
    $A.enqueueAction(action);
  },

  onDeleteDataset: function(component, event) {
    var action = component.get("c.deleteDataset");
    var datasetId = event.getSource().get("v.value");
    var dataType = component.get("v.dataType");
    var self = this;
    action.setParams({
      datasetId: datasetId,
      dataType: dataType
    });
    action.setCallback(this, function(response) {
      var event = component.getEvent("waitingEvent");
      event.fire();
      var state = response.getState();
      if (state === "ERROR") {
        self.handleErrors(response.getError());
      }
      self.onLoadDatasets(component);
    });
    var event = component.getEvent("waitingEvent");
    event.fire();
    $A.enqueueAction(action);
  },

  onTrainDataset: function(component, event) {
    var action = component.get("c.trainDataset");
    var datasetId = event.getSource().get("v.value");
    var dataType = component.get("v.dataType");
    var self = this;
    action.setParams({
      datasetId: datasetId,
      dataType: dataType
    });
    action.setCallback(this, function(response) {
      var event = component.getEvent("waitingEvent");
      event.fire();
      var state = response.getState();
      if (state === "ERROR") {
        self.handleErrors(response.getError());
      } else {
        self.handleConfirmation(
          "The model id for the training is " +
          response.getReturnValue() +
          ". Refresh the dataset for seeing the training progress.");
      }
    });
    var event = component.getEvent("waitingEvent");
    event.fire();
    $A.enqueueAction(action);
  }
  
});
