({
  init: function(component, event, helper) {
    component.set("v.shelfDataColumns", [
        { label: "Label", fieldName: "label", type: "text" },
        { label: "Count", fieldName: "count", type: "number" },
        { label: "Share of Shelf", fieldName: "percentage", type: "percent" }
      ]);

    // Set values (abstract EinsteinPlatformCard)
    component.set("v.hasData", true);
    component.set("v.cardLabel", component.get("v.title"));

    // Set default backgroud for image.  Setting this as the default of the attribute in the component
    // causes problems where the predicted image will not load.
    component.set("v.pictureSrc", $A.get('$Resource.einsteinplay__einstein_images') + '/einstein_images/EinsteinVIsionDefault.png');

  },

  onDragOver: function(component, event) {
      event.preventDefault();     
    },

  onDrop: function(component, event, helper) {
    event.stopPropagation();
    event.preventDefault();
    event.dataTransfer.dropEffect = 'copy';
    var files = event.dataTransfer.files;
    console.log('files: ');
    console.log(files[0]);
    if (files.length > 1) {
      return alert("You can only analyse one picture at a time");
    }
    if (files[0].size > 5000000) {
      return alert("The file exceeds the limit of 5MB.");
    }
    component.set("v.probability", "");
    helper.readFile(component, helper, files[0]);
  },
  
  handleUploadFinished: function(component, event, helper) {
       //  console.log("upload finished");
          var uploadedFiles = event.getParam("files");
          var contentId = '';
           var modelId = component.get("v.modelName");
          console.log("upload finished " + uploadedFiles.length);
          
          
          for(var i=0; i<uploadedFiles.length; i++) {
             console.log( uploadedFiles[i].name + ' - ' + uploadedFiles[i].documentId );
             contentId =  uploadedFiles[i].documentId;
          }
           component.set("v.attachId", contentId);
          
          helper.analyzeContent(component, contentId);
         
      },
      
    store: function(component, fileName, base64Data) {
      var action = component.get("c.storeScanResults");
      var shelfData = component.get("v.shelfData");
      action.setParams({
        jsonString: JSON.stringify(shelfData)
      });
      action.setCallback(this, function(a) {
        //  console.log("Got classification response");
        $A.get("e.force:refreshView").fire();
        var state = a.getState();
        if (state === "SUCCESS") {
          helper.handleConfirmation("The shelf scan has been saved.");
        } else if (state === "ERROR") {
          helper.handleError("An error has occurred.");
        }
     
      });
      $A.enqueueAction(action);
    },
      addItemstoRecords: function (component, event, helper){
        
          helper.createPredictionRecord(component);
      },
  });