global class Einstein_Probability {

    @AuraEnabled
    global String label {get; set;}
    @AuraEnabled
    global Double probability {get; set;}
    @AuraEnabled
    global String token {get; set;}
    @AuraEnabled
    global String normalizedValue {get;set;}

    @AuraEnabled
    global BoundingBox boundingBox {get; set;}

    global class BoundingBox {
        @AuraEnabled
        global Integer minX {get; set;}
        @AuraEnabled
        global Integer minY {get; set;}
        @AuraEnabled
        global Integer maxX {get; set;}
        @AuraEnabled
        global Integer maxY {get; set;}
    }

}