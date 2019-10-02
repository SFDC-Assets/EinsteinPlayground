({
	doInit : function(component) {
    	var action = component.get("c.getSettings");
 		
         
    	action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
             	var settings =  a.getReturnValue();
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

	
})