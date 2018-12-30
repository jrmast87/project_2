/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// An apex page controller that supports self registration of users in communities that allow self registration
// 
// Edited by: Evan W.
// 
// Addition(s): 
// 				List of accounts to check against.  
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class CommunitiesSelfRegController 
{
    public String firstName {get; set;}
    public String lastName {get; set;}
    public String email {get; set;}
    public String accountName {get; set;}
    public String password {get; set {password = value == null ? value : value.trim(); } }
    public String confirmPassword {get; set { confirmPassword = value == null ? value : value.trim(); } }
    public String communityNickname {get; set { communityNickname = value == null ? value : value.trim(); } }
    public String socialSecurityNumber {get;set;}
    public Decimal accountCode {get;set;}
    
    public CommunitiesSelfRegController() {
        String expid = ApexPages.currentPage().getParameters().get('expid');            
        if (expId != null) {
            Site.setExperienceId(expId); 
        }    
    }
    
    private boolean isValidPassword() {
        return password == confirmPassword;
    }

    public PageReference registerUser() {
    
           // it's okay if password is null - we'll send the user a random password in that case
        if (!isValidPassword()) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.site.passwords_dont_match);
            ApexPages.addMessage(msg);
            return null;
        }
		
		String profileID = null;
        String roleEnum = null; // To be filled in by customer.
        String accountId = ''; // To be filled in by customer.
        
        Double d = Math.random() * 9999.00D;
        String userName = firstName + '.' + lastName + '@brave-panda-w0etr2.com';

        User u = new User();
        u.Username = userName;
        u.Email = email;
        u.FirstName = firstName;
        u.LastName = lastName;
        u.CommunityNickname = communityNickname;
        
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
       	// Edited by: 	Evan W.
       	// Addition:	Check to insure the account entered is
       	// 				in our org, then attach the user
       	// 			 	to that exsiting account.
       	Account a = new Account();
       	try
        {
       		a = [SELECT ID, Account_Code__c
                 FROM Account
                 WHERE Name = :accountName];
        }
        catch (Exception e)
        {
        	ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,
                                 'Could not find ' + accountName + ' in our system.' +
                                 '  Please enter a valid account.'));
            system.debug('account query exception');
            return null;
        }
        
        if (a.Account_Code__c != accountCode)
        {
        	ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,
                                 'Incorrect account code' +
                                 '  Please enter correct account code.'));
        	return null;
        }
        
        accountID = a.ID;
        
        // Addition:	Check to see if the Contact is in the org
        // 				by email.  If not, add them to the Contact
        List<Contact> contactList = new List<Contact>();
        contactList = [SELECT ID, FirstName, LastName, Email, AccountID, Social_Security_Number__c
                       FROM Contact
                       WHERE Social_Security_Number__c = :socialSecurityNumber];
        if (!contactList.isEmpty())
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,
                                 'Social Security Number is already in use.  ' +
                                 'Please enter another Social Security Number'));
            system.debug('account query exception');
            return null;
        }


        //////////////////////////////////////////////////////END ADDITIONS//////////////////////////////////////////////////////
        
        
		String userID;
		
        try {
            //userId = Site.createExternalUser(u, accountId, password);
            
            userId = Site.createExternalUser(u, accountId, password);
        } catch(Site.ExternalUserCreateException ex) {
                List<String> errors = ex.getDisplayMessages();
            for (String error : errors)  {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
            }
            
            // This message is used for debugging. Do not display this in the UI to the end user.
            // It has the information around why the user creation failed.
            System.debug(ex.getMessage());
            return null;
        }
        
        if (userId != null) { 
            
            Contact c = new Contact();
            try
            {
            	c = [SELECT ID, Social_Security_Number__c
            		 FROM Contact
            		 WHERE firstName = :firstName];
            }
            catch(QueryException e)
            {
            	ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,
                                 'There was an error adding the contact.'));
            	system.debug('contact query exception for ssn');
            	return null;
            }
            c.Social_Security_Number__c = socialSecurityNumber;
            update c;
            
            if (password != null && password.length() > 1) {                
                return Site.login(userName, password, 'southernheartteam3-developer-edition.na85.force.com/CustomerPortal');
            }
            else {
                PageReference page = System.Page.CommunitiesSelfRegConfirm;
                page.setRedirect(true);
                return page;
            }
        }
        return null;
    }
}