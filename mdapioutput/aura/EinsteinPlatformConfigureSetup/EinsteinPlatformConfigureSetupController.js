({
	doInit : function(component, event, helper) {
        helper.getEinsteinSettings(component);
        
         helper.getUserId(component);
       
	},
    onCert : function(component, event, helper) {
        var settings  = component.get("v.settings");
        settings.Authentication_Type__c = "certificate";
          component.set("v.settings", settings);
    },
    onPem : function(component, event, helper) {
        var settings  = component.get("v.settings");
        settings.Authentication_Type__c = "pem file";
          component.set("v.settings", settings);
    },
     onCreateCert : function(component, event, helper) {
     },
    testConnect : function(component, event, helper) {
        var showVerify  = component.get("v.showVerify");
        showVerify = true;
        component.set("v.showVerify", showVerify);
        
      
	},
     save : function(component, event, helper) {
        var action = component.get("c.saveSettings");
 		var settings  = component.get("v.settings");
         action.setParams({
      		settings: settings,
    	});
         
    	action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "type": "success",
                    "message": "Settings Saved."
                });
                toastEvent.fire();
                
                var checkSettings = component.get("v.checkSettings");
                checkSettings = !checkSettings;
                component.set("v.checkSettings", checkSettings);
                
             	return;
            } else if (a.getState() === "ERROR") {                
    			$A.log("Errors", a.getError());
                helper.handleErrors(a.getError());
            }
   		});

    	$A.enqueueAction(action);
     },
     handleUploadFinished : function(component, event, helper) {

        var action = component.get("c.updatePemFile");
 		
               
        var uploadedFiles = event.getParam("files");
        var contentId = '';
        
        for(var i=0; i<uploadedFiles.length; i++) {
           contentId =  uploadedFiles[i].documentId;
        }
           component.set("v.pemId", contentId);
    
         action.setParams({
      		documentId: contentId
    	});
         
    	action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
                
                var certName =  a.getReturnValue();
                
               	var settings  = component.get("v.settings");
              //  settings.CertName__c = certName;
                settings.einsteinplay__CertName__c  = certName;
                component.set("v.settings", settings);
                
             	return;
            } else if (a.getState() === "ERROR") {                
    			$A.log("Errors", a.getError());
                helper.handleErrors(a.getError());
            }
   		});

    	$A.enqueueAction(action);

                 
     }
    
})