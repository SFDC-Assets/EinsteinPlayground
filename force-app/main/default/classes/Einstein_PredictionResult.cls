@JsonAccess(serializable='always' deserializable='always')
global with sharing class Einstein_PredictionResult {

    @AuraEnabled
    global List<Einstein_Probability> probabilities {get; set;}

    global List<Einstein_Probability> filter(String label, Double probability) {
        List<Einstein_Probability> filteredProbs = new List<Einstein_Probability>();
        for (Einstein_Probability checkProb : probabilities) {
            if (checkProb.label.equals(label)) {
                if (checkProb.probability>= probability) {
                    filteredProbs.add(checkProb);
                }
            }
        }
        return filteredProbs;
    }
        
}