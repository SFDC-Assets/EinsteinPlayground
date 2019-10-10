({  
     
      onDefaultModelId: function(component, event, helper) {
            var selectedModel = component.get("v.modelId");
            component.set("v.selectedModel", selectedModel);
      },
    
    
    onDragOver: function(component, event) {
        event.preventDefault();     
    },

    onDrop: function(component, event, helper) {
    	event.stopPropagation();
        event.preventDefault();
        event.dataTransfer.dropEffect = 'copy';
        var files = event.dataTransfer.files;
        console.log('files: ' + files[0]);
        if (files.length>1) {
            return alert("You can only analyse one picture at a time");
        }
        component.set("v.probability", "");
        helper.readFile(component, helper, files[0]);
  	},
    
    handleClick: function (component, event, helper){
        helper.createPredictionRecord(component);
    },
    
    onSelectChange : function(component, event, helper) {
      var selected = component.find("levels").get("v.value");
      var photoUrl = $A.get('$Resource.EinsteinVIsionDefault');
        console.log("selected " + selected);
        
    	component.set("v.modelId", selected);
        if (component.get("v.pictureSrc") !=  photoUrl) {
            component.set("v.probability", "");
           /* var base64Data = component.get("v.fileData").match(/,(.*)$/)[1];
             */
            var base64Data = component.get("v.fileData").match(/,(.*)$/)[1];
        
           helper.analyseAgain(component, base64Data);
        }
  },
    onFileSelected : function(component,event,helper) {
 
        var selectedFile = event.target.files[0];
        console.log("SelectedFile ",selectedFile);
        var reader = new FileReader();

        reader.onload = function(event) {
            imgtag.src = event.target.result;
        };
        component.set("v.probability", "");
      
               
        helper.readFile(component, helper, selectedFile);
},
    handleUploadFinished: function(component, event, helper) {
    
        var uploadedFiles = event.getParam("files");
        var contentId = '';
     
        var filename = '';
        console.log("upload finished " + uploadedFiles.length);

        for(var i=0; i<uploadedFiles.length; i++) {
            console.log( uploadedFiles[i].name + ' - ' + uploadedFiles[i].documentId );
            contentId =  uploadedFiles[i].documentId;
            filename =  uploadedFiles[i].name;
        }
         component.set("v.attachId", contentId);
         console.log("contentId is " + contentId);
         console.log("contentId is " + component.get("v.attachId"));
        
        helper.analyzeContent(component, contentId, filename);
       
    }

})