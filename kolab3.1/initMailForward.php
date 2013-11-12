<?php

require_once "/usr/share/kolab-webadmin/lib/functions.php";
require_once "/usr/share/kolab-webadmin/lib/api/kolab_api_service_user_types.php";

$conf = Conf::get_instance();
$primary_domain = $conf->get('kolab', 'primary_domain');
$ldappassword = $conf->get('ldap', 'bind_pw');
$_SESSION['user'] = new User();
$valid = $_SESSION['user']->authenticate("cn=Directory Manager", $ldappassword, $primary_domain);

if ($valid === false) {
        die ("cannot authenticate user cn=Directory Manager");
}

$auth = Auth::get_instance();

$user_types = new kolab_api_service_user_types(null);
$list = $user_types->user_types_list(null, null);
# copy the entry for kolab
if ($list['list'][1]['key'] != 'kolab') {
   echo ("failure: expected user type kolab at position 1, but found ".$list['list'][1]['key']). "\n";
   die();
}

$newType = array(
  'type' => 'user',
  'key' => 'forward',
  'name' => 'Forward Only',
  'description' => 'A Mail Forwarding Entry. No webmail access, mailforwarding only',
  'attributes' => array (
    'fields' => array (
      'objectclass' => array (
        0 => 'inetorgperson',
        1 => 'mailrecipient',
        2 => 'organizationalperson',
        3 => 'person',
        4 => 'top',
      ),
    ),
    'form_fields' => array (
      'givenname' => array (
      ),
      'mail' => array (
        'type' => 'list',
      ),
      'mailforwardingaddress' => array (
      ),
      'sn' => array (
      ),
    ),
    'auto_form_fields' => array (
      'cn' => array (
        'data' => array (
          0 => 'givenname',
          1 => 'sn',
        ),
      ),
      'uid' => array (
      ),
      'displayname' => array (
        'data' => array (
          0 => 'givenname',
          1 => 'sn',
        )
      )
    )
  )
);

$service_type = new kolab_api_service_type();
if (false === $service_type->type_add(null, $newType)) {
    echo "failure: was not able to add new user type forward\n";
    die();
}

echo "added new user type forward\n";

?>
