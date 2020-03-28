({       
    init: function(component, event, helper) {    
        // Set default backgroud for image.  Setting this as the default of the attribute in the component
        // causes problems where the predicted image will not load.
        component.set("v.pictureSrc", $A.get('$Resource.crisisapp__einstein_images') + '/einstein_images/EinsteinVIsionDefault.png');

	},

	onDragOver: function (component, event) {
        event.preventDefault();     
    },

	onDrop: function (component, event, helper) {
    	event.stopPropagation();
        event.preventDefault();
        event.dataTransfer.dropEffect = 'copy';
        var files = event.dataTransfer.files;
        console.log('files: ' + files[0]);
        if (files.length>1) {
            return alert("You can only analyse one picture at a time");
        }
        if (files[0].size > 5000000) {
            return alert("The file exceeds the limit of 5MB.");
          }
        component.set("v.probability", "");
        helper.readFile(component, helper, files[0]);
  	},

	handleClick: function (component, event, helper) {
        helper.createPredictionRecord(component);
    },

	onFileSelected: function (component, event, helper) {

		var selectedFile = event.target.files[0];
        console.log("SelectedFile ",selectedFile);
        var reader = new FileReader();

		reader.onload = function (event) {
            imgtag.src = event.target.result;
        };
        component.set("v.probability", "");


		helper.readFile(component, helper, selectedFile);
},

	handleUploadFinished: function (component, event, helper) {

		var uploadedFiles = event.getParam("files");
        var contentId = '';

		var filename = '';
        console.log("upload finished " + uploadedFiles.length);

		for (var i = 0; i < uploadedFiles.length; i++) {
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