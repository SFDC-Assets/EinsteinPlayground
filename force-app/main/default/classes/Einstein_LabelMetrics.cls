global class Einstein_LabelMetrics {

    @AuraEnabled
    global Decimal averagePrecision {get; set;}
    
    @AuraEnabled
    global String label {get; set;}
    
    @AuraEnabled
    global Decimal f1 {get;set;}
    
    @AuraEnabled
    global List<Decimal> precision {get; set;}
    
    @AuraEnabled
    global List<Decimal> recall {get; set;}
    
}
