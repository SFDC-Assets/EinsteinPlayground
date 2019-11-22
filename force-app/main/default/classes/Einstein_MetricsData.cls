global class Einstein_MetricsData {

    @AuraEnabled
    global List<List<Integer>> confusionMatrix {get; set;}
    
    @AuraEnabled
    global List<Decimal> f1 {get; set;}
    
    @AuraEnabled
    global List<String> labels {get;set;}
    
    @AuraEnabled
    global Decimal testAccuracy {get; set;}
    
    @AuraEnabled
    global Decimal trainingAccuracy {get; set;}
    
    @AuraEnabled
    global Decimal trainingLoss {get; set;}
    
}