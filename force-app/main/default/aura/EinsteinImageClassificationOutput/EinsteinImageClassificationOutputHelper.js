({
  readFile: function(component, helper, file) {
    if (!file) return;
    if (!file.type.match(/(image.*)/)) {
      return alert("Image file not supported");
    }
    var reader = new FileReader();
    reader.onloadend = function() {
      var dataURL = reader.result;
      component.set("v.fileData", dataURL);
      component.set("v.pictureSrc", dataURL);
      helper.analyse(component, dataURL.match(/,(.*)$/)[1]);
    };
    reader.readAsDataURL(file);
  },

  analyzeContent: function(component, contentId, filename) {
    var helper = this;
    var action = component.get("c.writeCD");

    action.setParams({
      contentDocumentId: contentId,
      name: filename
    });

    action.setCallback(this, function(response) {
      var state = response.getState();
      var errors = action.getError();
      if (state === "SUCCESS") {
        var returnValue = response.getReturnValue();
        component.set("v.pictureSrc", returnValue.ContentDownloadUrl);

        this.analyseUrl(component);

        helper.changeSpinner(component);
      } else if (state === "ERROR") {
        console.log("analyzeContent ERROR");
        $A.log("Errors", errors);
        this.handleErrors(errors);
      }
    });

    $A.enqueueAction(action);
  },

  analyseUrl: function(component) {
    component.set("v.spinnerWaiting", true);

    var action = component.get("c.predictImageClassificationURL");
    var recId = component.get("v.recordId");
    var modelId = component.get("v.modelId");
    var url = component.get("v.pictureSrc");

    action.setParams({
      modelId: modelId,
      url: url
    });

    action.setCallback(this, function(response) {
      component.set("v.spinnerWaiting", false);

      var state = response.getState();
      var errors = action.getError();
      if (state === "SUCCESS") {
        //  console.log("Success " );
        var returnValue = response.getReturnValue();

        var probabilities = returnValue.probabilities;

        var meterWidth = probabilities[0].probability * 100;

        component.set("v.prediction", probabilities[0].label);
        component.set("v.probability", probabilities[0].probability);
        component.set("v.meterWidth", Math.round(meterWidth));

        let postToChatter = component.get("v.postToChatter");
        if (postToChatter) {
          let contentId = component.get("v.attachId");
          console.log("Attach ID - " + contentId);
          this.postToChatter(component, contentId);
        }
      } else if (state === "ERROR") {
        $A.log("Errors", errors);
        this.handleErrors(errors);
      }
      component.set("v.spinnerWaiting", false);
    });

    $A.enqueueAction(action);
    component.set("v.prediction", "Getting prediction...");
  },

  analyse: function(component, base64Data) {
    var helper = this;
    helper.changeSpinner(component);

    var modelId = component.get("v.modelId");

    var action = component.get("c.predictImageClassification");
    action.setParams({
      base64: base64Data,
      modelId: modelId
    });

    action.setCallback(this, function(response) {
      helper.changeSpinner(component);

      //component.set("v.spinnerWaiting", false);

      var state = response.getState();
      var errors = action.getError();
      if (state === "SUCCESS") {
        /*  var toastEvent = $A.get("e.force:showToast");
    			toastEvent.setParams({  "title": "Success!",  "message": "The record has been updated successfully."});
   	 			toastEvent.fire(); */

        var returnValue = response.getReturnValue();

        var probabilities = returnValue.probabilities;

        var meterWidth = probabilities[0].probability * 100;

        component.set("v.prediction", probabilities[0].label);
        component.set("v.probability", probabilities[0].probability);
        component.set("v.meterWidth", Math.round(meterWidth));
        component.set("v.fileName", returnValue.original_fileName);
        component.set("v.attachId", returnValue.attachment_id);
      } else if (state === "ERROR") {
        $A.log("Errors", errors);
        this.handleErrors(errors);
      }
    });

    $A.enqueueAction(action);
    component.set("v.prediction", "Getting prediction...");
  },

  postToChatter: function(component, contentId) {

    var recId = component.get("v.recordId");

    var classification = component.get("v.prediction");
    var comment = "Analyzed photo and found it to be " + classification;
    console.log("Attach " + contentId);

    var action = component.get("c.postImageToChatter");
    action.setParams({
      recordId: recId,
      docId: contentId,
      comment: comment
    });

    action.setCallback(this, function(response) {
      var state = response.getState();
      var errors = action.getError();
      if (state === "SUCCESS") {
        //    console.log("postToChatter SUCCESS" );
      } else if (state === "ERROR") {
        console.log("analyzeContent ERROR");
        $A.log("Errors", errors);
        this.handleErrors(errors);
      }
    });
    $A.enqueueAction(action);
  },

  analyseAgain: function(component, base64Data) {
    // component.set("v.spinnerWaiting", true);
    var helper = this;
    helper.changeSpinner(component);

    var c_type = component.get("v.modelId");

    var action = component.get("c.analyseImage");
    action.setParams({
      base64Data: base64Data,
      modelName: c_type
    });

    action.setCallback(this, function(response) {
      //  component.set("v.spinnerWaiting", false);

      var state = response.getState();
      var errors = action.getError();
      if (state === "SUCCESS") {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
          title: "Success!",
          message: "The record has been updated successfully."
        });
        toastEvent.fire();

        var returnValue = response.getReturnValue();

        var probabilities = returnValue.probabilities;

        var meterWidth = probabilities[0].probability * 100;

        component.set("v.prediction", probabilities[0].label);
        component.set("v.probability", probabilities[0].probability);
        component.set("v.meterWidth", Math.round(meterWidth));
        component.set("v.fileName", returnValue.original_fileName);
        component.set("v.attachId", returnValue.attachment_id);
      } else if (state === "ERROR") {
        $A.log("Errors", errors);
        this.handleErrors(errors);
      }

      helper.changeSpinner(component);
    });

    $A.enqueueAction(action);
    component.set("v.prediction", "Getting prediction...");
  },

  createPredictionRecord: function(component) {
    var objectName = component.get("v.objectName");
    var fieldName = component.get("v.fieldName");
    var intentLabel = component.get("v.prediction");
    var recordId = component.get("v.recordId");

    if (objectName == null || objectName.length == 0) {
      return;
    }

    if (fieldName == null || fieldName.length == 0) {
      return;
    }
    var action = component.get("c.createRecord");

    action.setParams({
      recordId: recordId,
      objectName: objectName,
      fieldName: fieldName,
      intentLabel: intentLabel
    });

    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var returnValue = response.getReturnValue();
        // Prepare a toast UI message
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
          title: "Success",
          message: "Einstein prediction saved successfully."
        });
        $A.get("e.force:refreshView").fire();
        $A.get("e.force:closeQuickAction").fire();
        resultsToast.fire();
      } else if (state === "ERROR") {
        $A.log("Errors", response.getError());
        this.handleErrors(response.getError());
      }
    });

    $A.enqueueAction(action);
  }
});