<?php
$hosted_domain = isset($argv[1])?$argv[1]:"";
$hosted_domain_root_dn="dc=".implode(",dc=",explode(".", $hosted_domain));

# Do we have all infos to continue?
if($hosted_domain=="" || $hosted_domain_root_dn=="") {
	die("Usage: ".$argv[0]." <hosted domain>\n".
	"e.g. ".$argv[0]." kolab.example.org\n");
}

# attach code from template to /etc/kolab/kolab.conf
$conf = file_get_contents("domain.kolab.conf.tpl");
$conf = str_replace('{$hosted_domain}', $hosted_domain, $conf);
$conf = str_replace('{$hosted_domain_root_dn}', $hosted_domain_root_dn, $conf);
file_put_contents("/etc/kolab/kolab.conf", $conf, FILE_APPEND | LOCK_EX);

system("service httpd reload");

?>
