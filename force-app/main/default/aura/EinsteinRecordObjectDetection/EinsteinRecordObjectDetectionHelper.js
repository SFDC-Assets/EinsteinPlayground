({
  readFile: function(component, helper, file) {
    if (!file) return;
    if (!file.type.match(/(image.*)/)) {
      return alert("Image file not supported");
    }
    var reader = new FileReader();
    reader.onloadend = function() {
      var dataURL = reader.result;
      component.set("v.pictureSrc", dataURL);
      component.set("v.fileName", file.name);
      console.log('readFile dataURL: ' + dataURL);
      console.log('readFile pictureSrc: ' + component.get("v.pictureSrc"));

      helper.analyse(component, file, dataURL.match(/,(.*)$/)[1]);
    };
    reader.readAsDataURL(file);
  },

  upload: function(component, fileName, base64Data) {
    var helper = this;
    var imgContainer = component.find("imgContainer").getElement();
    while (imgContainer.firstChild) {
      imgContainer.removeChild(imgContainer.firstChild);
    }
    var action = component.get("c.detectObjects");
    var modelId = component.get("v.modelId");
    action.setParams({
      modelId: modelId,
      base64: base64Data
    });
    action.setCallback(this, function(a) {
      helper.changeSpinner(component);
      var state = a.getState();
      if (state === "ERROR") {
        console.log(a);
        var errors = a.getError();
        this.handleErrors(errors);
        return;
      }

      var result = a.getReturnValue();
      var rawPredictions = JSON.stringify(result, null, 4);
      component.set("v.predictions", result);
      component.set("v.rawPredictions", rawPredictions);
      var ro = new ResizeObserver(entries => {
        this.generateSvg(component);
      });
      var img = component.find("imgItself").getElement();
      ro.observe(img);
      this.calculateShelfData(component);
      component.set("v.showDatatable", true);

      var postToChatter = component.get("v.postToChatter");
      var attachImage = component.get("v.attachImage");

      if (postToChatter && !attachImage) {
        let errors = [];
        let errorItem = {
          message:
            "Vision Component Configuration Error: Posting to chatter requires a file attachment. Please double check lightning component configuration."
        };
        errors[0] = errorItem;

        this.handleErrors(errors);
      }
    });
    component.set("v.predictions", null);
    component.set("v.rawPredictions", null);
    helper.changeSpinner(component);
    $A.enqueueAction(action);
  },

  generateSvg: function(component) {
    var imgContainer = component.find("imgContainer").getElement();
    // Remove any existing DIVs from overlay 
    while (imgContainer.firstChild) {
      imgContainer.removeChild(imgContainer.firstChild);
    }
    var img = component.find("imgItself").getElement();

    var proportion = img.clientHeight / img.naturalHeight;
    if (proportion > 1) {
      proportion = 1;
    }

    var predictions = component.get("v.predictions");
    if (predictions == null) {
      return;
    }

    var probabilities = predictions.probabilities;

    var svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    var svgNS = svg.namespaceURI;

    var leftPos = img.offsetLeft;
    var topPos = img.offsetTop;

    var colors = this.buildColorCoding(probabilities);

    probabilities.forEach(function(probability) {
      var color = colors[probability.label];
      // create polygon for box
      var polygon = document.createElementNS(svgNS, "polygon");
      polygon.setAttribute(
        "style",
        "stroke:" + color + ";"
      );
      var points = [];
      points.push(
        (probability.boundingBox.minX * proportion + leftPos) +
        "," +
        (probability.boundingBox.minY * proportion + topPos)
    );
    points.push(
        (probability.boundingBox.maxX * proportion + leftPos) +
        "," +
        (probability.boundingBox.minY * proportion + topPos)
    );
    points.push(
        (probability.boundingBox.maxX * proportion + leftPos) +
        "," +
        (probability.boundingBox.maxY * proportion + topPos)
    );
    points.push(
        (probability.boundingBox.minX * proportion + leftPos) +
        "," +
        (probability.boundingBox.maxY * proportion + topPos)
    );
    polygon.setAttribute("points", points.join(" "));
    polygon.classList.add('polygon');
    
    svg.appendChild(polygon);

      // create text box
      var div = document.createElement("div");
      div.setAttribute(
        "style",
        "position:absolute;top:" +
          probability.boundingBox.maxY * proportion +
          "px;left:" +
          (probability.boundingBox.minX * proportion + leftPos) +
          "px;width:" +
          (probability.boundingBox.maxX - probability.boundingBox.minX) *
            proportion +
          "px;text-align:center;color:" +
          color +
          ";"
      );
      div.innerHTML = probability.label;
      imgContainer.appendChild(div);
    }, this);
    imgContainer.appendChild(svg);
  },

  // generates a palette of high-contrast colors
  buildColorCoding: function (probabilities) {
      var colors = {};
      var uniqueLabels = _.uniq(_.map(probabilities, 'label'));

      var colorArray = [
          '#e6194b',
          '#3cb44b',
          '#ffe119',
          '#0082c8',
          '#f58231',
          '#911eb4',
          '#46f0f0',
          '#f032e6',
          '#d2f53c',
          '#fabebe',
          '#008080',
          '#e6beff',
          '#aa6e28',
          '#fffac8',
          '#800000',
          '#aaffc3',
          '#808000',
          '#ffd8b1',
          '#000080',
          '#808080',
          '#FFFFFF',
          '#000000'
      ]

      for (var i = 0; i < uniqueLabels.length; i++) {
          // OCR could return more labels than this list of colors,
          // so wrap around and reuse, if necessary
          colors[uniqueLabels[i]] = colorArray[i % colorArray.length];
      }
      return colors;
  },

calculateShelfData: function(component) {
    var probabilities = component.get("v.predictions").probabilities;
    var calcObjects = {};
    var shelfData = [];
    var allObjects = 0;
    probabilities.forEach(function(probability) {
      allObjects += 1;
      if (typeof calcObjects[probability.label] === "undefined") {
        var calcObject = {};
        calcObject.count = 1;
        calcObject.label = probability.label;
        calcObjects[probability.label] = calcObject;
      } else {
        calcObjects[probability.label].count += 1;
      }
    });
    Object.keys(calcObjects).forEach(function(label) {
      calcObjects[label].percentage = (
        calcObjects[label].count / allObjects
      ).toFixed(2);
      shelfData.push(calcObjects[label]);
    });
    component.set("v.shelfData", shelfData);
  },
  
  createPredictionRecord: function(component) {
    console.log("createPredictionRecord 3");

    var objectName = component.get("v.objectName");
    var labelFieldName = component.get("v.labelFieldName");
    var countFieldName = component.get("v.countFieldName");
    var intentLabel = component.get("v.prediction");
    var recordId = component.get("v.recordId");
    var shelfData = component.get("v.shelfData");

    if (objectName == null || objectName.length == 0) {
      console.log("objectName null");
      return;
    }

    if (
      (labelFieldName == null || labelFieldName.length == 0) &&
      (countFieldName == null || countFieldName.length == 0)
    ) {
      console.log("Fields null");
      return;
    }

    var value;

    var objectList = [];

    //{"Data": {"attributes":

    for (var i = 0; i < shelfData.length; i++) {
      console.log(shelfData[i]);
      value = '{"sobjectType":"' + objectName + '"';
      //  value = "{\"" +  objectName + "\":{\"attributes\":{"
      if (labelFieldName != null && labelFieldName.length >= 0) {
        value =
          value + ',"' + labelFieldName + '": "' + shelfData[i].label + '"';
      }
      if (countFieldName != null && countFieldName.length >= 0) {
        value =
          value + ',"' + countFieldName + '": "' + shelfData[i].count + '"';
      }
      value = value + "} ";
      console.log(value);

      var action = component.get("c.storeScanResults");
      action.setParams({
        dataJson: value,
        recordId: recordId,
        objectName: objectName
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
          var errors = response.getError();
          this.handleErrors(errors);
        }
      });

      $A.enqueueAction(action);
    }
  },

  analyzeContent: function(component, contentId) {

    var action = component.get("c.createContentUrl");

    action.setParams({
      contentDocumentId: contentId
    });

    action.setCallback(this, function(response) {
      console.log("Got Response analyzeContent ");

      var state = response.getState();
      var errors = action.getError();
      if (state === "SUCCESS") {
        var returnValue = response.getReturnValue();
        console.log("analyzeContent SUCCESS " + returnValue);
        component.set("v.pictureSrc", returnValue);

        this.analyseUrl(component);
      } else if (state === "ERROR") {
        console.log("analyzeContent ERROR");
        $A.log("Errors", errors);
        this.handleErrors(errors);
      }
    });

    console.log("Sending ..");
    $A.enqueueAction(action);
  },

  postToChatter: function(component, contentId) {
    var action = component.get("c.postImageToChatter");

    var recId = component.get("v.recordId");
    var contentId = component.get("v.attachId");
    var classification = component.get("v.prediction");
    var comment = "Analyzed photo.";
    console.log("Attach " + contentId);
    //postImageToChatter(String recordId, String docId, String comment) {
    action.setParams({
      recordId: recId,
      docId: contentId,
      comment: comment
    });

    action.setCallback(this, function(response) {
      var state = response.getState();
      var errors = action.getError();
      if (state === "SUCCESS") {
        console.log("postToChatter SUCCESS");
      } else if (state === "ERROR") {
        console.log("analyzeContent ERROR");
        $A.log("Errors", errors);
        this.handleErrors(errors);
      }
    });

    $A.enqueueAction(action);
  },

  analyseUrl: function(component) {
    var helper = this;

    var recId = component.get("v.recordId");
    var modelId = component.get("v.modelId");
    var url = component.get("v.pictureSrc");

    console.log("Analyzing " + url + " with " + modelId);

    var action = component.get("c.analyseImageUrl");
    action.setParams({
      modelName: modelId,
      url: url
    });

    action.setCallback(this, function(response) {
      helper.changeSpinner(component);

      console.log("Got Response analyseUrl ");

      var state = response.getState();
      var errors = action.getError();
      if (state === "SUCCESS") {
        var result = response.getReturnValue();
        var rawPredictions = JSON.stringify(result, null, 4);
        component.set("v.predictions", result);
        component.set("v.rawPredictions", rawPredictions);
        var ro = new ResizeObserver(entries => {
          this.generateSvg(component);
        });
        var img = component.find("imgItself").getElement();
        ro.observe(img);
        this.calculateShelfData(component);
        component.set("v.showDatatable", true);

        var postToChatter = component.get("v.postToChatter");
        if (postToChatter) {
          this.postToChatter(component);
        }
      } else if (state === "ERROR") {
        $A.log("Errors", errors);
        this.handleErrors(errors);
      }
    });

    console.log("Sending ..");
    helper.changeSpinner(component);
    $A.enqueueAction(action);
    component.set("v.prediction", "Getting prediction...");
  },

  analyse: function(component, file, base64Data) {
    var helper = this;

    component.set("v.message", file.name);
    var recId = component.get("v.recordId");
    var modelId = component.get("v.modelId");

    console.log("Analyzing " + modelId);

    var action = component.get("c.detectObjects");
    action.setParams({
      modelId: modelId,
      base64: base64Data
    });

    action.setCallback(this, function(response) {
      helper.changeSpinner(component);

      console.log("Got Response ");

      var state = response.getState();
      var errors = action.getError();
      console.log('state: ' + state + '  errors: ');
      console.log(errors);

      if (state === "SUCCESS") {
        var result = response.getReturnValue();
        var rawPredictions = JSON.stringify(result, null, 4);
        component.set("v.predictions", result);
        component.set("v.rawPredictions", rawPredictions);
        var ro = new ResizeObserver(entries => {
          this.generateSvg(component);
        });
        var img = component.find("imgItself").getElement();
        ro.observe(img);
        this.calculateShelfData(component);
        component.set("v.showDatatable", true);

      } else if (state === "ERROR") {
        //   component.set("v.message", "Something went wrong " + errors[0].message);
        $A.log("Errors", errors);
        this.handleErrors(errors);
      }
    });

    console.log("Sending ..");
    helper.changeSpinner(component);
    $A.enqueueAction(action);
    component.set("v.prediction", "Getting prediction...");
  },
  handleErrors: function(errors) {
    // Configure error toast
    let toastParams = {
      title: "Error",
      message: "Unknown error", // Default error message
      type: "error"
    };
    // Pass the error message if any
    if (errors && Array.isArray(errors) && errors.length > 0) {
      toastParams.message = errors[0].message;
    }
    // Fire error toast
    let toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams(toastParams);
    toastEvent.fire();
  }
});