public with sharing class VCR_AccountMatch {
    public class Request {
        @InvocableVariable(required=true) public String vendorName;
        @InvocableVariable public String vendorWebsite;
        @InvocableVariable public String vendorPhone;
        @InvocableVariable public String vendorStreet;
        @InvocableVariable public String vendorCity;
        @InvocableVariable public String vendorState;
        @InvocableVariable public String vendorPostalCode;
        @InvocableVariable public String vendorCountry;
        @InvocableVariable public Boolean createIfMissing;   // pass true from Flow
        @InvocableVariable public String defaultRecordTypeId;
        @InvocableVariable public Id ownerId;                // e.g., $Record.OwnerId
    }
    public class Response {
        @InvocableVariable public Id accountId;
        @InvocableVariable public Boolean created;
        @InvocableVariable public Integer matchScore;
        @InvocableVariable public String usedDomain;
        @InvocableVariable public String normalizedVendorName;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(label='VCR Find or Create Account')
    public static List<Response> findOrCreate(List<Request> reqs) {
        List<Response> outs = new List<Response>();
        if (!Schema.sObjectType.Account.isAccessible()) {
            Response o = new Response();
            o.errorMessage = 'Current user does not have read access to Account.';
            outs.add(o);
            return outs;
        }
        for (Request r : reqs) {
            Response o = new Response();
            try {
                // Normalize inputs (treat "unknown" and blanks as null)
                String normName = normalizeName(nullIfUnknown(r.vendorName));
                String domain   = toDomain(nullIfUnknown(r.vendorWebsite));
                String phone    = digitsOnly(nullIfUnknown(r.vendorPhone));
                String street   = nullIfUnknown(r.vendorStreet);
                String city     = safeLower(nullIfUnknown(r.vendorCity));
                String state    = safeLower(nullIfUnknown(r.vendorState));
                String postal   = safeLower(nullIfUnknown(r.vendorPostalCode));
                String country  = safeLower(nullIfUnknown(r.vendorCountry));

                if (String.isBlank(normName) && String.isBlank(domain) && String.isBlank(phone)) {
                    o.errorMessage = 'No match keys (name/website/phone) provided';
                    outs.add(o); 
                    continue;
                }

                // Gather candidates
                Set<Id> seen = new Set<Id>();
                List<Account> candidates = new List<Account>();

                if (!String.isBlank(domain)) {
                    for (Account a : [
                        SELECT Id, Name, Website, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                        FROM Account WHERE Website LIKE :('%'+domain+'%') LIMIT 150
                    ]) if (seen.add(a.Id)) candidates.add(a);
                }
                if (!String.isBlank(phone)) {
                    for (Account a : [
                        SELECT Id, Name, Website, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                        FROM Account WHERE Phone != NULL LIMIT 500
                    ]) if (digitsOnly(a.Phone) == phone && seen.add(a.Id)) candidates.add(a);
                }
                List<String> tokens = nameTokens(normName, 2);
                if (!tokens.isEmpty()) {
                    String like1 = '%' + tokens[0] + '%';
                    String like2 = (tokens.size() > 1) ? '%' + tokens[1] + '%' : null;
                    String soql = 'SELECT Id, Name, Website, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry FROM Account WHERE Name LIKE :like1 ';
                    if (like2 != null) soql += 'OR Name LIKE :like2 ';
                    soql += 'LIMIT 200';
                    for (Account a : Database.query(soql)) if (seen.add(a.Id)) candidates.add(a);
                }

                // Score
                Integer bestScore = -1; Account best = null;
                for (Account a : candidates) {
                    Integer s = 0;
                    String aNorm = normalizeName(a.Name);
                    if (!String.isBlank(normName)) {
                        if (aNorm == normName) s += 90;
                        Integer hits = 0; for (String t : tokens) if (aNorm.contains(t)) hits++;
                        s += hits * 15; // up to +30
                    }
                    String aDom = toDomain(a.Website);
                    if (!String.isBlank(domain) && domain == aDom) s += 80;
                    if (!String.isBlank(phone) && digitsOnly(a.Phone) == phone) s += 70;
                    if (!String.isBlank(postal)  && safeLower(a.BillingPostalCode) == postal)  s += 40;
                    if (!String.isBlank(city)    && safeLower(a.BillingCity)       == city)    s += 20;
                    if (!String.isBlank(state)   && safeLower(a.BillingState)      == state)   s += 15;
                    if (!String.isBlank(country) && safeLower(a.BillingCountry)    == country) s += 10;

                    if (s > bestScore) { bestScore = s; best = a; }
                }

                if (best != null && bestScore >= 70) {
                    o.accountId = best.Id; 
                    o.created = false; 
                    o.matchScore = bestScore;
                    o.usedDomain = domain; 
                    o.normalizedVendorName = normName;
                } else if (r.createIfMissing == true) {
                    if (!Schema.sObjectType.Account.isCreateable()) {
                        o.errorMessage = 'Current user does not have create access to Account.';
                        outs.add(o);
                        continue;
                    }
                    Account na = new Account();
                    na.Name = String.isBlank(r.vendorName) ? (String.isBlank(domain) ? 'New Vendor' : domain) : r.vendorName;
                    if (!String.isBlank(domain)) na.Website = 'https://' + domain;
                    if (!String.isBlank(r.vendorPhone)) na.Phone = formatE164OrLocal(r.vendorPhone);
                    na.BillingStreet     = street;
                    na.BillingCity       = nullIfUnknown(r.vendorCity);
                    na.BillingState      = nullIfUnknown(r.vendorState);
                    na.BillingPostalCode = nullIfUnknown(r.vendorPostalCode);
                    na.BillingCountry    = nullIfUnknown(r.vendorCountry);
                    if (r.ownerId != null) na.OwnerId = r.ownerId;
                    if (!String.isBlank(r.defaultRecordTypeId)) na.RecordTypeId = r.defaultRecordTypeId;
                    insert na;

                    o.accountId = na.Id; 
                    o.created = true; 
                    o.matchScore = 0;
                    o.usedDomain = domain; 
                    o.normalizedVendorName = normName;
                } else {
                    o.accountId = null; 
                    o.created = false;
                    o.matchScore = (bestScore < 0 ? 0 : bestScore);
                    o.usedDomain = domain; 
                    o.normalizedVendorName = normName;
                }
            } catch (Exception e) {
                o.errorMessage = e.getMessage().left(255);
            }
            outs.add(o);
        }
        return outs;
    }

    // ---------- helpers ----------
    private static String nullIfUnknown(String s){
        if (s == null) return null;
        String t = s.trim();
        if (t.equalsIgnoreCase('unknown') || t == '') return null;
        return t;
    }
    private static String digitsOnly(String s){
        if (String.isBlank(s)) return null;
        String t = s.replaceAll('[^0-9]','');
        return String.isBlank(t) ? null : t;
    }
    private static String formatE164OrLocal(String s){
        if (String.isBlank(s)) return null;
        String t = s.trim();
        if (t.startsWith('+')) return t;
        String d = digitsOnly(t);
        if (d == null) return t;
        if (d.length() == 10) return '('+d.substring(0,3)+') '+d.substring(3,6)+'-'+d.substring(6);
        return d;
    }
    private static String normalizeName(String s){
        if (String.isBlank(s)) return null;
        String out = s.toLowerCase();
        out = out.replaceAll('[^a-z0-9 ]',' ');
        out = out.replaceAll('\\b(incorporated|inc|corp|corporation|llc|l\\.l\\.c|ltd|limited|co|company|gmbh|sarl|s\\.a\\.|bv|oy|pty|pte)\\b','');
        out = out.replaceAll('\\s+',' ').trim();
        return out;
    }
    private static String toDomain(String url){
        if (String.isBlank(url)) return null;
        String u = url.toLowerCase().trim();
        u = u.replace('http://','').replace('https://','');
        if (u.startsWith('www.')) u = u.substring(4);
        Integer cut = u.length();
        for (Integer i : new Integer[]{u.indexOf('/'),u.indexOf('?'),u.indexOf('#')}) if (i > -1 && i < cut) cut = i;
        u = u.substring(0,cut);
        return u.contains('.') ? u : null;
    }
    private static List<String> nameTokens(String norm, Integer max){
        List<String> out = new List<String>();
        if (String.isBlank(norm)) return out;
        for (String t : norm.split(' ')){
            if (t != null && t.length() >= 3) out.add(t);
            if (out.size() >= max) break;
        }
        return out;
    }
    private static String safeLower(String s){ return String.isBlank(s) ? null : s.trim().toLowerCase(); }
}