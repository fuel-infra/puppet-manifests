import hudson.model.Item
import hudson.model.Computer
import hudson.model.Hudson
import hudson.model.Run
import hudson.model.View
import hudson.security.GlobalMatrixAuthorizationStrategy
import hudson.security.AuthorizationStrategy
import hudson.security.Permission
import jenkins.model.Jenkins

class InvalidAuthenticationStrategy extends Exception{}

class Actions {
  Actions(out) { this.out = out }
  def out

  ///////////////////////////////////////////////////////////////////////////////
  // this -> is set_security
  ///////////////////////////////////////////////////////////////////////////////
  //
  // Sets up security for the Jenkins Master instance.
  //
  void set_security(String security_model, String overwrite_permissions=null, String item_perms=null, String server=null, String rootDN=null,  String userSearch=null, String inhibitInferRootDN=null, String userSearchBase=null, String groupSearchBase=null, String managerDN=null, String managerPassword=null) {

    if (inhibitInferRootDN==null) {
      inhibitInferRootDN = false
    }
    def instance = Jenkins.getInstance()
    def strategy
    def realm

    if (security_model == 'ldap') {
      if (!(instance.getAuthorizationStrategy() instanceof hudson.security.GlobalMatrixAuthorizationStrategy)) {
        overwrite_permissions = 'true'
      }
      strategy = new hudson.security.GlobalMatrixAuthorizationStrategy()
      for (Permission p : Item.PERMISSIONS.getPermissions()) {
        strategy.add(p,item_perms)
      }
      for (Permission p : Computer.PERMISSIONS.getPermissions()) {
        strategy.add(p,item_perms)
      }
      for (Permission p : Hudson.PERMISSIONS.getPermissions()) {
        strategy.add(p,item_perms)
      }
      for (Permission p : Run.PERMISSIONS.getPermissions()) {
        strategy.add(p,item_perms)
      }
      for (Permission p : View.PERMISSIONS.getPermissions()) {
        strategy.add(p,item_perms)
      }
      realm = new hudson.security.LDAPSecurityRealm(server, rootDN, userSearchBase, userSearch, groupSearchBase, managerDN, managerPassword, inhibitInferRootDN.toBoolean())
    } else if (security_model == 'unsecured') {
        strategy = new hudson.security.AuthorizationStrategy.Unsecured()
        realm = new hudson.security.HudsonPrivateSecurityRealm(false, false, null)
        overwrite_permissions = 'true'
    } else {
        throw new InvalidAuthenticationStrategy()
    }
    // apply new strategy&realm
    if (overwrite_permissions == 'true') {
      instance.setAuthorizationStrategy(strategy)
    }
    instance.setSecurityRealm(realm)
    // commit new settings permanently (in config.xml)
    instance.save()
  }
}

///////////////////////////////////////////////////////////////////////////////
// CLI Argument Processing
///////////////////////////////////////////////////////////////////////////////

actions = new Actions(out)
action = args[0]
if (args.length < 2) {
  actions."$action"()
} else {
  actions."$action"(*args[1..-1])
}
