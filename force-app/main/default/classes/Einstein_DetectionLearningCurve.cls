global class Einstein_DetectionLearningCurve {

    @AuraEnabled
    public Long epoch {get; set;}
    
    @AuraEnabled
    // Detection models return an empty object for EpochResults.  Go figure.
    public EpochResults epochResults {get; set;}
    
    @AuraEnabled
    public Einstein_DetectionMetricsData metricsData {get; set;}
}