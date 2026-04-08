public with sharing class CVMS_AccountWrapper {
    
    /*public class Request {
        public List<AccountData> accounts;

        public Request(List<Account> accountList) {
            this.accounts = new List<AccountData>();
            for (Account acc : accountList) {
                this.accounts.add(new AccountData(acc));
            }
        }
    }*/

    public class AccountData {
        public String SFAccountId;
        public String AccountName;
        public String CustomerSegment;
        public String Industry;
        public String BillingStreet;
        public String BillingCity;
        public String BillingStateProvince;
        public String BillingZipPostalCode;
        public String BillingCountry;

        public AccountData(Account acc) {
            this.SFAccountId = acc.Id;
            this.accountName = acc.Name;
            this.customerSegment = acc.Company_Size__c;
            this.industry = acc.Industry;
            this.billingStreet = acc.BillingStreet;
            this.billingCity = acc.BillingCity;
            this.BillingStateProvince = acc.BillingState;
            this.BillingZipPostalCode = acc.BillingPostalCode;
            this.billingCountry = acc.BillingCountry;
        }
    }

    public class Response {
        public List<ResponseData> results;
    }

    public class ResponseData {
        public String sfAccountId;
        public String status;
        public String errorMessage;
         public String statusCode;
    }
}