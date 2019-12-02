global class Einstein_MultiLearningCurve {

    @AuraEnabled
    public Long epoch {get; set;}
    
    @AuraEnabled
    public List<EpochResults> epochResults {get; set;}
    
    @AuraEnabled
    public Einstein_MetricsData metricsData {get; set;}
}