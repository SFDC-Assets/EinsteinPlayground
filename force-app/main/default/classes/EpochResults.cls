global class EpochResults {

    @AuraEnabled
    global String exampleName {get; set;}
    @AuraEnabled
    global String expectedLabel {get; set;}
    @AuraEnabled
    global String predictedLabel {get; set;}
}