({
	changeSpinner: function (component, event, helper) {
		console.log('changeSpinner');
    	helper.changeSpinner(component);
  },

  	updateModelSelection: function (component, event, helper) {
		console.log('updateModelSelection');
		helper.updateModelSelection(component, event);
  	},

	doInitPlayground: function (component, event, helper) {
		console.log('doInitPlayground');
    	component.set("v.modelsByType", {});
    	helper.enableTabs(component, event);
  }
});