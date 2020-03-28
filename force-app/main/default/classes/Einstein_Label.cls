global with sharing class Einstein_Label {
    @AuraEnabled
    global Integer id {get; set;}
    @AuraEnabled
    global Integer datasetId {get; set;}
    @AuraEnabled 
    global String name {get; set;}
    @AuraEnabled
    global Integer numExamples {get; set;}
}