global class Einstein_Probability {

    @AuraEnabled
    global String label {get; set;}
    @AuraEnabled
    global Double probability {get; set;}
    @AuraEnabled
    global String token {get; set;}
    @AuraEnabled
    global String normalizedValue {get; set;}

    @AuraEnabled
    global Attributes attributes {get; set;}

    @AuraEnabled
    global BoundingBox boundingBox {get; set;}


    global class Attributes {

        @AuraEnabled
        global CellLocation cellLocation {get; set;}
        @AuraEnabled
        global String tag {get; set;}
    }

    global class CellLocation {
        @AuraEnabled
        global Integer colIndex {get; set;}
        @AuraEnabled
        global Integer rowIndex {get; set;}
    }

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