({
    
     getEinsteinSettings : function(component) {
    	var action = component.get("c.getSettings");
 		var helper = this;
         
    	action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
				var settings = a.getReturnValue();
				console.log ("Get Settings: ", settings),
                component.set("v.settings",settings);

                if(settings.CacheName__c != null) {
                      component.set("v.enableCache",true);
                }
                
            } else if (a.getState() === "ERROR") {                
    			
                helper.handleErrors(a.getError());
            }
   		});

    	$A.enqueueAction(action);
     },
   
     getUserId : function(component) {
    	var action = component.get("c.getMyUserId");
 		var helper = this;
         
    	action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
             	var userId =  a.getReturnValue();
                component.set("v.userId",userId);
            } else if (a.getState() === "ERROR") {                
                helper.handleErrors(a.getError());
            }
   		});

    	$A.enqueueAction(action);
     }
})