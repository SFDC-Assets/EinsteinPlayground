public class Einstein_LanguageLearningCurve {

    @AuraEnabled
    public Long epoch {get; set;}
    
    @AuraEnabled
    // Language models return an empty object for EpochResults.  Go figure.
    public EpochResults epochResults {get; set;}
    
    @AuraEnabled
    public Einstein_MetricsData metricsData {get; set;}
}