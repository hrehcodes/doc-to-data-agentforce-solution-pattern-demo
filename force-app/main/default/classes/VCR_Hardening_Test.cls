@IsTest
private class VCR_Hardening_Test {
    @IsTest static void parseExtractJsonMapsTypedFields() {
        VCR_ParseExtractJson.Request req = new VCR_ParseExtractJson.Request();
        req.json = '{"Vendor_Name__c":"Acme","Contract_Value__c":"$1,250.00","Auto_Renew__c":"false","Auto_Renew_Period_Months__c":"12","Payment_Terms_Days__c":"30"}';
        List<VCR_ParseExtractJson.Response> out = VCR_ParseExtractJson.parse(new List<VCR_ParseExtractJson.Request>{ req });
        System.assertEquals('Acme', out[0].vendorName);
        System.assertEquals(1250, out[0].contractValue);
        System.assertEquals(null, out[0].autoRenewPeriodMonths);
        System.assertEquals(30, out[0].paymentTermsDays);
    }
    @IsTest static void parseAnalysisJsonClampsScores() {
        VCR_ParseAnalysisJson.Request req = new VCR_ParseAnalysisJson.Request();
        req.json = '{"Risk_Score__c":150,"Risk_Class__c":"High","Needs_Review__c":"yes","Lowest_Confidence_0100__c":"-5","Risk_Justification__c":"Review required"}';
        List<VCR_ParseAnalysisJson.Response> out = VCR_ParseAnalysisJson.parse(new List<VCR_ParseAnalysisJson.Request>{ req });
        System.assertEquals(100, out[0].riskScore);
        System.assertEquals(0, out[0].lowestConfidence0100);
        System.assertEquals(true, out[0].needsReview);
    }
    @IsTest static void accountMatchFindsExistingAccount() {
        Account a = new Account(Name='Acme Corporation', Website='https://acme.example.com');
        insert a;
        VCR_AccountMatch.Request req = new VCR_AccountMatch.Request();
        req.vendorName = 'Acme Corp';
        req.vendorWebsite = 'https://acme.example.com/products';
        req.createIfMissing = false;
        List<VCR_AccountMatch.Response> out = VCR_AccountMatch.findOrCreate(new List<VCR_AccountMatch.Request>{ req });
        System.assertEquals(a.Id, out[0].accountId);
        System.assertEquals(false, out[0].created);
    }
}
