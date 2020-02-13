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
         console.log('--- settings -- ' , settings);
         action.setParams({
      		settings: settings,
    	});
         
    	action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
                helper.handleConfirmation("Settings Saved.");
                
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
    
    delSettings : function(component, event, helper)
    {
        var action = component.get("c.deleteSettings");
        action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
                helper.handleWarning("All Einstein Settings have been DELETED!");
                helper.getEinsteinSettings(component);
               // return;
            } else {
                helper.handleWarning("Deletion Failed. Navigate to Setup --> Custom Settings --> Einstein Settings --> Manage. To manually delete.");
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

        action.setParams({
      		documentId: contentId
    	});
         
    	action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
                var certName =  a.getReturnValue();
               	var settings  = component.get("v.settings");
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