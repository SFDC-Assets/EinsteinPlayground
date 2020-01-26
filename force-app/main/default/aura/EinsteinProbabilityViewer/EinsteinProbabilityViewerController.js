({
    doInit : function(component, event, helper) {

        var sample =  {
            attributes: {
                cellLocation: {
                    colIndex: 1,
                    rowIndex: 1
                }
            },
            boundingBox: {
                maxX: 116,
                maxY: 19,
                minX: 48,
                minY: 8
            },
            label: "Enrollment",
            probability: 0.98460346
        };

        component.set("v.probability", sample);
    }
})
