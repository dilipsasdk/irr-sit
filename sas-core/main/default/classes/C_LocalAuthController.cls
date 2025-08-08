/**
 * @author Peter Södergren
 * @description Controller for the local authentication which is used
 *              to retrieve a username and password for an external service
 */
public with sharing class C_LocalAuthController {
    /**
        The username to use when authenticating
    */
    public String username{get;set;}
    /**
        The password to use when authenticating
    */
    public String password{get;set;}
    /**
    First additional parameter for authentication
    */
    public String param1{get;set;}
    /**
        Second additional parameter for authentication
    */
    public String param2{get;set;}
    /**
        The access token after authenticating
    */
    public String accessToken{get;private set;}
    /**
        The state to to reply back with
    */
    public String state{get;private set;}
    /**
        Class name of the auth connector
    */
    public String authConnectorClassName{get;private set;}
    /**
        The redirect uri after authenticating
    */
    public String redirectUri{get;private set;}
    /**
        Configures the authentication
    */
    public C_LocalAuthController(){
        state = ApexPages.currentPage().getParameters().get('state');
        authConnectorClassName = ApexPages.currentPage().getParameters().get('authConnector');
        redirectUri = ApexPages.currentPage().getParameters().get('redirectUri');
    }

    /**
     * Authenticates against the endpoint redirects the user back to the auth provider
     * @return A null page reference since the script will re-route to prevent
     */
    public PageReference authenticate(){
        accessToken = null;
        try{
            C_LocalAuthConnector ac = (C_LocalAuthConnector)Type.forName(authConnectorClassName).newInstance();
            accessToken = ac.authenticate(username, password, param1, param2);
        }
        catch(Exception e){
            ApexPages.addMessages(e);
        }
        return null;
    }
}
