public  class CVMS_ContactWrapper {
    
    
    public class Request {
        public List<ContactData> contacts;
        
        public Request(List<Contact> contactList) {
            this.contacts = new List<ContactData>();
            for (Contact con : contactList) {
                this.contacts.add(new ContactData(con));
            }
        }
    }
    
    
    public class ContactData {
        public String SFContactId;
        public String SFAccountId;
       // public String AccountName;
        public String FirstName;
        public String LastName;
        public String Email;
        public String Phone;
        public String OfficePhone;
        public String Designation;
        public String ReportsTo;
        
        public ContactData(Contact con) {
            this.SFAccountId = con.AccountId; 
            this.SFContactId = con.Id; 
           // this.AccountName = con.Account.Name;
            this.FirstName = con.FirstName;
            this.LastName = con.LastName;
            this.Email = con.Email;
            this.Phone = con.MobilePhone;
            this.OfficePhone = con.Phone;
            this.Designation = con.Title;
            this.ReportsTo = con.ReportsTo.Id; 
        }
    }
    
    
    public class Response {
        public List<ResponseData> results;
    }
    
    
    public class ResponseData {
        public String sfContactId;
        public String status;
        public String statusCode;
        public String message;
    }
}