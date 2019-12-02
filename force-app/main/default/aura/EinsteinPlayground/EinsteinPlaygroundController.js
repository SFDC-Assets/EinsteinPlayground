({
  changeSpinner: function(component, event, helper) {
    helper.changeSpinner(component);
  },

  updateModelSelection: function (component, event, helper) {
    helper.updateModelSelection(component, event);
  },

  doInitPlayground: function(component, event, helper) {
    component.set("v.modelsByType", {});
    helper.enableTabs(component, event);
  }
});