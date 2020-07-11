({

	doInitPlayground: function (component, event, helper) {
		console.log('doInitPlayground');
    	component.set("v.modelsByType", {});
    	helper.enableTabs(component, event);
  }
});