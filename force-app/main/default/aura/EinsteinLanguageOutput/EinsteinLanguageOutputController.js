({
  handleFeedback: function(component, event, helper) {
    let modelId = helper.getModelId(component);

    if (modelId == "CommunitySentiment") {
      helper.handleErrors([{message: 'Feedback cannot be created for community models'}]);
      return;
    }

    let index = event.getSource().get("v.value");
    let predictionList = component.get("v.predictionList");
    let label = predictionList[index].label;
    let text = component.get("v.intentPhrase");

    for (var i = 0; i < predictionList.length; i++) {
      if (i == index) {
        predictionList[i].liked = true;
        predictionList[i].icon = "utility:like";
      } else {
        predictionList[i].liked = false;
        predictionList[i].icon = "utility:close";
      }
    }
    component.set("v.predictionList", predictionList);

    let action = component.get("c.createFeedbackLanguageExample");

    action.setParams({
      modelId: modelId,
      expectedLabel: label,
      text: text
    });
    action.setCallback(this, function(res) {
      let state = res.getState();
      let retVal = res.getReturnValue();

      if (state === "SUCCESS") {
        helper.handleConfirmation("Feedback Received.");
      } else {
        helper.handleErrors(res.getError());
      }
    });

    $A.enqueueAction(action);
  },
  predictionChange: function(component, event, helper) {
    let predictionList = component.get("v.predictionList");
    for (var i = 0; i < predictionList.length; i++) {
      if (predictionList[i].icon == null) {
        predictionList[i].liked = false;
        predictionList[i].icon = "utility:like";
      }
    }
  }
});
