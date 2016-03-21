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

$kolabUserType = $list['list'][1];
$kolabUserType['id'] = 1;
$kolabUserType['type'] = 'user';
$kolabUserType['attributes']['fields']['objectclass'][] = 'tbitskolabuser';
$kolabUserType['attributes']['form_fields']['tbitskolablastlogin'] = array('type' => 'text-unixtimestamp', 'optional' => 1);
$service_type = new kolab_api_service_type(null);
if (false === $service_type->type_edit(null, $kolabUserType)) {
    echo "failure: was not able to save user type kolab\n";
    die();
}

$newType = $kolabUserType;
unset($newType['id']);
unset($newType['is_default']);
$newType['type'] = 'user';
$newType['key'] = 'domainadmin';
$newType['name'] = 'Domain Administrator';
$newType['description'] = 'A Kolab Domain Administrator';
$newType['attributes']['fields']['objectclass'][] = 'tbitskolabdomainadmin';
unset($newType['attributes']['fields']['objectclass']['mailrecipient']);
unset($newType['attributes']['auto_form_fields']['alias']);
unset($newType['attributes']['auto_form_fields']['mailhost']);
unset($newType['attributes']['auto_form_fields']['mail']);
unset($newType['attributes']['form_fields']['mailquota']);
unset($newType['attributes']['form_fields']['mailalternateaddress']);
unset($newType['attributes']['form_fields']['alias']);
unset($newType['attributes']['form_fields']['mail']);
unset($newType['attributes']['form_fields']['kolabdelegate']);
unset($newType['attributes']['form_fields']['kolaballowsmtprecipient']);
unset($newType['attributes']['form_fields']['kolaballowsmtpsender']);
unset($newType['attributes']['form_fields']['kolabinvitationpolicy']);
$newType['attributes']['form_fields']['tbitskolabmaxaccounts'] = array('type' => 'text', 'optional' => 1);
$newType['attributes']['form_fields']['tbitskolaboverallquota'] = array('type' => 'text-quota', 'optional' => 1);
$newType['attributes']['form_fields']['tbitskolabdefaultquota'] = array('type' => 'text-quota', 'optional' => 1);

if (false === $service_type->type_add(null, $newType)) {
    echo "failure: was not able to add new user type domainadmin\n";
    die();
}

echo "added new user type domainadmin\n";
?>
