import hudson.model.Item
import hudson.model.Computer
import hudson.model.Hudson
import hudson.model.Run
import hudson.model.View
import hudson.security.GlobalMatrixAuthorizationStrategy
import hudson.security.AuthorizationStrategy
import hudson.security.Permission
import hudson.tasks.Shell
import jenkins.model.Jenkins
import jenkins.model.JenkinsLocationConfiguration
import jenkins.security.s2m.AdminWhitelistRule
import com.cloudbees.plugins.credentials.CredentialsMatchers
import com.cloudbees.plugins.credentials.CredentialsProvider
import com.cloudbees.plugins.credentials.common.StandardUsernameCredentials
import com.cloudbees.plugins.credentials.domains.SchemeRequirement
import com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.CredentialsScope
import hudson.markup.RawHtmlMarkupFormatter
import hudson.markup.EscapedMarkupFormatter
import org.jenkinsci.plugins.UnsafeMarkupFormatter
import com.sonyericsson.hudson.plugins.gerrit.trigger.config.Config
import com.sonyericsson.hudson.plugins.gerrit.trigger.GerritServer
import com.sonyericsson.hudson.plugins.gerrit.trigger.PluginImpl

class InvalidAuthenticationStrategy extends Exception{}
class InvalidUserCredentials extends Exception{}
class InvalidUser extends Exception{}

class Actions {
  Actions(out) { this.out = out }
  def out

  ///////////////////////////////////////////////////////////////////////////////
  // this is -> setup_shell
  ///////////////////////////////////////////////////////////////////////////////
  //
  // Allows to set specific shell in Jenkins Master instance
  //
  void setup_shell(String shell) {
    def shl = new Shell.DescriptorImpl()
    shl.setShell(shell)
    shl.save()
  }

  ///////////////////////////////////////////////////////////////////////////////
  // this is -> enable_slave_to_master_acl
  ///////////////////////////////////////////////////////////////////////////////
  //
  // Allows to enable/disable SlaveToMasterAccessControl feature
  //
  void enable_slave_to_master_acl(String act) {
    def s2m = new AdminWhitelistRule()
    if(act == "true") {
      // for 'enabled' state we need to pass 'false'
      s2m.setMasterKillSwitch(false)
    }
    if(act == "false") {
      s2m.setMasterKillSwitch(true)
    }
    // requires Jenkins restart
    Hudson.instance.safeRestart()
  }

  ///////////////////////////////////////////////////////////////////////////////
  // this is -> cred_for_user
  ///////////////////////////////////////////////////////////////////////////////
  //
  // Helper in retrieving user's credentials
  //
  private cred_for_user(String user) {
    def user_match = CredentialsMatchers.withUsername(user)
    def available_cred = CredentialsProvider.lookupCredentials(
      StandardUsernameCredentials.class,
      Jenkins.getInstance(),
      hudson.security.ACL.SYSTEM,
      new SchemeRequirement("ssh")
    )
    return CredentialsMatchers.firstOrNull(available_cred, user_match)
  }

  ///////////////////////////////////////////////////////////////////////////////
  // this is -> user_info
  ///////////////////////////////////////////////////////////////////////////////
  //
  // Prints everything it can about the user
  //
  void user_info(String user) {
    def get_user = hudson.model.User.get(user, false)
    if(get_user == null) {
      throw new InvalidUser()
    }
    def user_id = get_user.getId()
    def name = get_user.getFullName()
    def email_addr = null
    def email_property = get_user.getProperty(hudson.tasks.Mailer.UserProperty)
    if(email_property != null) {
      email_addr = email_property.getAddress()
    }
    def ssh_keys = null
    def ssh_keys_property = get_user.getProperty(org.jenkinsci.main.modules.cli.auth.ssh.UserPropertyImpl)
    if(ssh_keys_property != null) {
      keys = ssh_keys_property.authorizedKeys.split('\\s+')
    }
    def token = null
    def api_token_property = get_user.getProperty(jenkins.security.ApiTokenProperty.class)
    if (api_token_property != null) {
      token = api_token_property.getApiToken()
    }
    def joutput = new groovy.json.JsonBuilder()
    joutput {
      id user_id
      full_name name
      email email_addr
      api_token token
      public_keys ssh_keys
    }
    // outputs in json format user's details
    out.println(joutput)
  }

  ///////////////////////////////////////////////////////////////////////////////
  // this is -> create credentials
  ///////////////////////////////////////////////////////////////////////////////
  //
  // Sets up (or updates) credentials for a particular user
  //
  void create_update_cred(String user, String passwd, String descr=null, String priv_key=null) {
    def global_domain = Domain.global()
    def cred_store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
    def cred
    if(priv_key==null) {
      cred = new UsernamePasswordCredentialsImpl(CredentialsScope.GLOBAL, null, descr, user, passwd)
    } else {
      def key_src
      if (priv_key.startsWith('-----BEGIN')) {
        key_src = new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(priv_key)
      } else {
        key_src = new BasicSSHUserPrivateKey.FileOnMasterPrivateKeySource(priv_key)
      }
      cred = new BasicSSHUserPrivateKey(CredentialsScope.GLOBAL, null, user, key_src, passwd, descr)
    }
    def current_cred = cred_for_user(user)
    if (current_cred != null) {
      cred_store.updateCredentials(global_domain, current_cred, cred)
    } else {
      cred_store.addCredentials(global_domain, cred)
    }
  }

  ///////////////////////////////////////////////////////////////////////////////
  // this -> is create_update_user
  ///////////////////////////////////////////////////////////////////////////////
  //
  // Creates or updates user
  //
  void create_update_user(String user, String email, String passwd=null, String name=null, String pub_keys=null) {
    def set_user = hudson.model.User.get(user)
    set_user.setFullName(name)
    def email_property = new hudson.tasks.Mailer.UserProperty(email)
    set_user.addProperty(email_property)
    def pw_details = hudson.security.HudsonPrivateSecurityRealm.Details.fromPlainPassword(passwd)
    set_user.addProperty(pw_details)
    if (pub_keys != null && pub_keys !="") {
      def ssh_keys_property = new org.jenkinsci.main.modules.cli.auth.ssh.UserPropertyImpl(pub_keys)
      set_user.addProperty(ssh_keys_property)
    }
    set_user.save()
  }

  ///////////////////////////////////////////////////////////////////////////////
  // this -> is del_user
  ///////////////////////////////////////////////////////////////////////////////
  //
  // Deletes user
  //
  void del_user(String user) {
    def rm_user = hudson.model.User.get(user, false)
    if (rm_user != null) {
      rm_user.delete()
    }
  }

  ///////////////////////////////////////////////////////////////////////////////
  // this -> is del_credentials
  ///////////////////////////////////////////////////////////////////////////////
  //
  // Deletes credential for particular user
  //
  void del_cred(String user) {
    def current_cred = cred_for_user(user)
    if(current_cred != null) {
      def global_domain = com.cloudbees.plugins.credentials.domains.Domain.global()
      def cred_store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
      cred_store.removeCredentials(global_domain, current_cred)
    }
  }

  ///////////////////////////////////////////////////////////////////////////////
  // this is -> cred_info
  ///////////////////////////////////////////////////////////////////////////////
  //
  // Retrieves current credentials for a user
  //
  void cred_info(String user) {
    def cred = cred_for_user(user)
    if(cred == null) {
      throw new InvalidUserCredentials()
    }
    def current_cred = [ id:cred.id, description:cred.description, username:cred.username ]
    if ( cred.hasProperty('password') ) {
      current_cred['password'] = cred.password.plainText
    } else {
      current_cred['private_key'] = cred.privateKey
      current_cred['passphrase'] = cred.passphrase.plainText
    }
    def joutput = new groovy.json.JsonBuilder(current_cred)
    // output in json format.
    out.println(joutput)
  }

  ///////////////////////////////////////////////////////////////////////////////
  // this -> is set_security
  ///////////////////////////////////////////////////////////////////////////////
  //
  // Sets up security for the Jenkins Master instance.
  //
  void set_security_ldap(
    String overwrite_permissions=null,
    String item_perms=null,
    String server=null,
    String rootDN=null,
    String userSearch=null,
    String inhibitInferRootDN=null,
    String userSearchBase=null,
    String groupSearchBase=null,
    String managerDN=null,
    String managerPassword=null,
    String ldapuser,
    String email=null,
    String password,
    String name=null,
    String pub_keys=null,
    String s2m_acl=null
  ) {

    if (inhibitInferRootDN==null) {
      inhibitInferRootDN = false
    }
    def instance = Jenkins.getInstance()
    def strategy
    def realm
    List users = item_perms.split(' ')

    if (!(instance.getAuthorizationStrategy() instanceof hudson.security.GlobalMatrixAuthorizationStrategy)) {
      overwrite_permissions = 'true'
    }
    create_update_user(ldapuser, email, password, name, pub_keys)
    strategy = new hudson.security.GlobalMatrixAuthorizationStrategy()
    for (String user : users) {
      for (Permission p : Item.PERMISSIONS.getPermissions()) {
        strategy.add(p,user)
      }
      for (Permission p : Computer.PERMISSIONS.getPermissions()) {
        strategy.add(p,user)
      }
      for (Permission p : Hudson.PERMISSIONS.getPermissions()) {
        strategy.add(p,user)
      }
      for (Permission p : Run.PERMISSIONS.getPermissions()) {
        strategy.add(p,user)
      }
      for (Permission p : View.PERMISSIONS.getPermissions()) {
        strategy.add(p,user)
      }
    }
    realm = new hudson.security.LDAPSecurityRealm(
      server, rootDN, userSearchBase, userSearch, groupSearchBase, managerDN, managerPassword, inhibitInferRootDN.toBoolean()
    )
    // apply new strategy&realm
    if (overwrite_permissions == 'true') {
      instance.setAuthorizationStrategy(strategy)
    }
    instance.setSecurityRealm(realm)
    // commit new settings permanently (in config.xml)
    instance.save()
    // now setup s2m if requested
    if(s2m_acl != null) {
      enable_slave_to_master_acl(s2m_acl)
    }
  }

  void set_unsecured() {
    def instance = Jenkins.getInstance()
    def strategy
    def realm
    strategy = new hudson.security.AuthorizationStrategy.Unsecured()
    realm = new hudson.security.HudsonPrivateSecurityRealm(false, false, null)
    instance.setAuthorizationStrategy(strategy)
    instance.setSecurityRealm(realm)
    instance.save()
  }

  void set_security_password(String user, String email, String password, String name=null, String pub_keys=null, String s2m_acl=null) {
    def instance = Jenkins.getInstance()
    def overwrite_permissions
    def strategy
    def realm
    strategy = new hudson.security.GlobalMatrixAuthorizationStrategy()
    if (!(instance.getAuthorizationStrategy() instanceof hudson.security.GlobalMatrixAuthorizationStrategy)) {
      overwrite_permissions = 'true'
    }
    create_update_user(user, email, password, name, pub_keys)
    for (Permission p : Item.PERMISSIONS.getPermissions()) {
      strategy.add(p,user)
    }
    for (Permission p : Computer.PERMISSIONS.getPermissions()) {
      strategy.add(p,user)
    }
    for (Permission p : Hudson.PERMISSIONS.getPermissions()) {
      strategy.add(p,user)
    }
    for (Permission p : Run.PERMISSIONS.getPermissions()) {
      strategy.add(p,user)
    }
    for (Permission p : View.PERMISSIONS.getPermissions()) {
      strategy.add(p,user)
    }
    realm = new hudson.security.HudsonPrivateSecurityRealm(false)
    // apply new strategy&realm
    if (overwrite_permissions == 'true') {
      instance.setAuthorizationStrategy(strategy)
      instance.setSecurityRealm(realm)
    }
    // commit new settings permanently (in config.xml)
    instance.save()
    // now setup s2m if requested
    if(s2m_acl != null) {
      enable_slave_to_master_acl(s2m_acl)
    }
  }

  ///////////////////////////////////////////////////////////////////////////////
  // Sets up jenkins global configuration
  ///////////////////////////////////////////////////////////////////////////////
  //
  void set_main_configuration(
    String jenkins_admin_email=null,
    String markup_formatter=null,
    String num_of_executors=null,
    String scm_checkout_retry_count=null
    ) {
    //updating admin email configuration
    def location = JenkinsLocationConfiguration.get()
    location.setAdminAddress(jenkins_admin_email)
    location.save()

    //enabling markup formatter
    Jenkins jenkins = Jenkins.getInstance()
    if (markup_formatter == "raw-html") {
      Jenkins.instance.setMarkupFormatter(new RawHtmlMarkupFormatter(false))
    } else if (markup_formatter == "plain-text") {
      Jenkins.instance.setMarkupFormatter(new EscapedMarkupFormatter())
    } else if (markup_formatter == "unsafe") {
      Jenkins.instance.setMarkupFormatter(new UnsafeMarkupFormatter())
    }

    //updating number of executors for master node
    if (jenkins.getNumExecutors() != Integer.parseInt(num_of_executors)) {
      jenkins.setNumExecutors(Integer.parseInt(num_of_executors))
    }

    //update scm checkout retry count
    if (jenkins.getScmCheckoutRetryCount() != Integer.parseInt(scm_checkout_retry_count)) {
      jenkins.setScmCheckoutRetryCount(Integer.parseInt(scm_checkout_retry_count))
    }
    //saving changes
    jenkins.save()
  }

///////////////////////////////////////////////////////////////////////////////
// Gerrit trigger configuration
///////////////////////////////////////////////////////////////////////////////

  void setup_gerrit(
    String gerrit_hostname = null,
    String gerrit_key_path = null,
    String gerrit_server_name = null,
    String gerrit_url = null,
    String gerrit_username = null
  ) {
    Config config
    if (PluginImpl.getInstance().getServer(gerrit_server_name) == null) {
        GerritServer defaultServer = new GerritServer(gerrit_server_name)
        config = defaultServer.getConfig()
        PluginImpl.getInstance().addServer(defaultServer)
        defaultServer.start()
    } else {
        config = PluginImpl.getInstance().getServer(gerrit_server_name).getConfig()
    }
    config.setGerritBuildCurrentPatchesOnly(true)
    config.setGerritHostName(gerrit_hostname)
    config.setGerritFrontEndURL(gerrit_url)
    config.setGerritUserName(gerrit_username)
    config.setGerritAuthKeyFile(new File(gerrit_key_path))
    PluginImpl.getInstance().save()
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
