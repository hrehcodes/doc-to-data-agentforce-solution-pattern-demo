public with sharing class VCR_ParseExtractJson {
    // ---- Flow input ----
    public class Request {
        @InvocableVariable(required=true)
        public String json; // raw JSON from the prompt template
    }

    // ---- Flow outputs (typed) ----
    public class Response {
        // Texts
        @InvocableVariable(label='Vendor_Name__c')        public String vendorName;
        @InvocableVariable(label='Contract_Title__c')     public String contractTitle;
        @InvocableVariable(label='Currency_Code__c')      public String currencyCode;
        @InvocableVariable(label='CurrencyIsoCode')       public String currencyIsoCode;
        @InvocableVariable(label='Liability_Cap_Text__c') public String liabilityCapText;
        @InvocableVariable(label='Source_Excerpts__c')    public String sourceExcerpts;

        // NEW: vendor contact details (kept as Flow variables; not written to the object unless you map them)
        @InvocableVariable(label='Vendor_Website__c')     public String vendorWebsite;
        @InvocableVariable(label='Vendor_Phone__c')       public String vendorPhone;
        @InvocableVariable(label='Vendor_Street__c')      public String vendorStreet;
        @InvocableVariable(label='Vendor_City__c')        public String vendorCity;
        @InvocableVariable(label='Vendor_State__c')       public String vendorState;
        @InvocableVariable(label='Vendor_Postal_Code__c') public String vendorPostalCode;
        @InvocableVariable(label='Vendor_Country__c')     public String vendorCountry;

        // Numbers/Currency
        @InvocableVariable(label='Contract_Value__c')             public Decimal contractValue;
        @InvocableVariable(label='Payment_Terms_Days__c')         public Integer paymentTermsDays;
        @InvocableVariable(label='Auto_Renew_Period_Months__c')   public Integer autoRenewPeriodMonths;
        @InvocableVariable(label='Notice_Period_Days__c')         public Integer noticePeriodDays;

        // Booleans
        @InvocableVariable(label='Auto_Renew__c')                    public Boolean autoRenew;
        @InvocableVariable(label='Termination_for_Convenience__c')   public Boolean terminationForConvenience;
        @InvocableVariable(label='Indemnity_Present__c')             public Boolean indemnityPresent;
        @InvocableVariable(label='Data_Processing_DPA_Required__c')  public Boolean dataProcessingDpaRequired;
        @InvocableVariable(label='SecuritySLA_Present__c')           public Boolean securitySlaPresent;

        // Pass-through JSON (optional)
        @InvocableVariable(label='confidences_json') public String confidencesJson;

        // Error reporting
        @InvocableVariable(label='error_message') public String errorMessage;
    }

    @InvocableMethod(label='Parse VCR Extract JSON'
                     description='Deserializes extractor JSON to typed Flow outputs')
    public static List<Response> parse(List<Request> reqs) {
        List<Response> results = new List<Response>();
        for (Request r : reqs) {
            Response out = new Response();
            try {
                if (String.isBlank(r.json)) {
                    out.errorMessage = 'Empty JSON input';
                    results.add(out);
                    continue;
                }
                Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r.json);

                // Texts
                out.vendorName       = getText(m, 'Vendor_Name__c');
                out.contractTitle    = getText(m, 'Contract_Title__c');
                out.currencyCode     = getText(m, 'Currency_Code__c');
                out.currencyIsoCode  = getText(m, 'CurrencyIsoCode');
                out.liabilityCapText = getText(m, 'Liability_Cap_Text__c');
                out.sourceExcerpts   = getText(m, 'Source_Excerpts__c');

                // NEW: vendor contact details
                out.vendorWebsite     = getText(m, 'Vendor_Website__c');
                out.vendorPhone       = getText(m, 'Vendor_Phone__c');
                out.vendorStreet      = getText(m, 'Vendor_Street__c');
                out.vendorCity        = getText(m, 'Vendor_City__c');
                out.vendorState       = getText(m, 'Vendor_State__c');
                out.vendorPostalCode  = getText(m, 'Vendor_Postal_Code__c');
                out.vendorCountry     = getText(m, 'Vendor_Country__c');

                // Numbers
                out.contractValue          = toDecimalClean(m.get('Contract_Value__c'));
                out.paymentTermsDays       = toInteger(m.get('Payment_Terms_Days__c'));
                out.autoRenewPeriodMonths  = toInteger(m.get('Auto_Renew_Period_Months__c'));
                out.noticePeriodDays       = toInteger(m.get('Notice_Period_Days__c'));

                // Booleans
                out.autoRenew                 = toBoolean(m.get('Auto_Renew__c'));
                out.terminationForConvenience = toBoolean(m.get('Termination_for_Convenience__c'));
                out.indemnityPresent          = toBoolean(m.get('Indemnity_Present__c'));
                out.dataProcessingDpaRequired = toBoolean(m.get('Data_Processing_DPA_Required__c'));
                out.securitySlaPresent        = toBoolean(m.get('SecuritySLA_Present__c'));

                // Pass-through confidences if present
                Object conf = m.get('confidences');
                if (conf != null) out.confidencesJson = JSON.serialize(conf);

                // Guardrail: if auto-renew is false, null out the period
                if (out.autoRenew == false) {
                    out.autoRenewPeriodMonths = null;
                }
            } catch (Exception e) {
                out.errorMessage = e.getMessage().left(255);
            }
            results.add(out);
        }
        return results;
    }

    // ---- Helpers ----
    private static String getText(Map<String,Object> m, String key) {
        Object v = m.get(key);
        return v == null ? null : String.valueOf(v);
    }
    private static Integer toInteger(Object v) {
        if (v == null) return null;
        if (v instanceof Integer) return (Integer) v;
        String s = String.valueOf(v).replaceAll('[^0-9-]', '');
        return String.isBlank(s) ? null : Integer.valueOf(s);
    }
    private static Decimal toDecimalClean(Object v) {
        if (v == null) return null;
        if (v instanceof Decimal) return (Decimal) v;
        String s = String.valueOf(v).replaceAll('[^0-9.-]', ''); // strip $, commas, units
        return String.isBlank(s) ? null : Decimal.valueOf(s);
    }
    private static Boolean toBoolean(Object v) {
        if (v == null) return null;
        if (v instanceof Boolean) return (Boolean) v;
        String s = String.valueOf(v).trim().toLowerCase();
        if (s == 'true' || s == '1' || s == 'yes')  return true;
        if (s == 'false' || s == '0' || s == 'no')  return false;
        return null;
    }
}