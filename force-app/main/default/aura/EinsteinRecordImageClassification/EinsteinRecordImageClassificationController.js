({
  onInit: function(component, event, helper) {
    // Set values (abstract EinsteinPlatformCard)
    component.set("v.hasData", true);
    component.set("v.cardLabel", component.get("v.title"));
  }
  
});
