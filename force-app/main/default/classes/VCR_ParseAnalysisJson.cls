public with sharing class VCR_ParseAnalysisJson {
    // -------- Input from Flow --------
    public class Request {
        @InvocableVariable(required=true)
        public String json; // raw JSON returned by the analyzer prompt
    }

    // -------- Outputs back to Flow (typed) --------
    public class Response {
        @InvocableVariable(label='Risk_Score__c')                 public Integer riskScore;
        @InvocableVariable(label='Risk_Class__c')                 public String  riskClass;
        @InvocableVariable(label='Needs_Review__c')               public Boolean needsReview;
        @InvocableVariable(label='Lowest_Confidence_0100__c')     public Integer lowestConfidence0100;
        @InvocableVariable(label='Risk_Justification__c')         public String  riskJustification;

        @InvocableVariable(label='error_message')                 public String  errorMessage; // non-null if parsing failed
    }

    @InvocableMethod(label='Parse VCR Analysis JSON'
                     description='Deserializes analyzer JSON to typed Flow outputs')
    public static List<Response> parse(List<Request> reqs) {
        List<Response> outs = new List<Response>();
        for (Request r : reqs) {
            Response o = new Response();
            try {
                if (String.isBlank(r.json)) {
                    o.errorMessage = 'Empty JSON input';
                    outs.add(o); continue;
                }
                Map<String,Object> m = (Map<String,Object>) JSON.deserializeUntyped(r.json);

                o.riskScore             = toInteger(m.get('Risk_Score__c'));
                o.riskClass             = toText(m.get('Risk_Class__c'));
                o.needsReview           = toBoolean(m.get('Needs_Review__c'));
                o.lowestConfidence0100  = toInteger(m.get('Lowest_Confidence_0100__c'));
                o.riskJustification     = truncateTo(String.valueOf(m.get('Risk_Justification__c')), 131000);

                // Guardrails: clamp to [0..100] where appropriate
                if (o.riskScore != null)            o.riskScore            = clamp(o.riskScore, 0, 100);
                if (o.lowestConfidence0100 != null) o.lowestConfidence0100 = clamp(o.lowestConfidence0100, 0, 100);
            } catch (Exception e) {
                o.errorMessage = e.getMessage().left(255);
            }
            outs.add(o);
        }
        return outs;
    }

    // -------- Helpers --------
    private static String toText(Object v) {
        return v == null ? null : String.valueOf(v);
    }
    private static Integer toInteger(Object v) {
        if (v == null) return null;
        if (v instanceof Integer) return (Integer) v;
        String s = String.valueOf(v).replaceAll('[^0-9-]', '');
        return String.isBlank(s) ? null : Integer.valueOf(s);
    }
    private static Boolean toBoolean(Object v) {
        if (v == null) return null;
        if (v instanceof Boolean) return (Boolean) v;
        String s = String.valueOf(v).trim().toLowerCase();
        if (s == 'true' || s == '1' || s == 'yes')  return true;
        if (s == 'false' || s == '0' || s == 'no')  return false;
        return null;
    }
    private static Integer clamp(Integer v, Integer lo, Integer hi) {
        if (v == null) return null;
        return (v < lo) ? lo : (v > hi ? hi : v);
    }
    private static String truncateTo(String s, Integer maxLen) {
        if (s == null) return null;
        return s.length() > maxLen ? s.left(maxLen) : s;
    }
}