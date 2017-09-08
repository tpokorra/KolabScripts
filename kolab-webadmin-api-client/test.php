<?php
/*
 +--------------------------------------------------------------------------+
 |                                                                          |
 | Copyright (C) 2016-2017, TBits.net                                       |
 |                                                                          |
 | This program is free software: you can redistribute it and/or modify     |
 | it under the terms of the GNU Affero General Public License as published |
 | by the Free Software Foundation, either version 3 of the License, or     |
 | (at your option) any later version.                                      |
 |                                                                          |
 | This program is distributed in the hope that it will be useful,          |
 | but WITHOUT ANY WARRANTY; without even the implied warranty of           |
 | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the             |
 | GNU Affero General Public License for more details.                      |
 |                                                                          |
 | You should have received a copy of the GNU Affero General Public License |
 | along with this program. If not, see <http://www.gnu.org/licenses/>      |
 +--------------------------------------------------------------------------+
 | Author: Timotheus Pokorra <tp@tbits.net>                                 |
 +--------------------------------------------------------------------------+
*/

include "test.config.php";
require_once("kolab_api_client.php");

function process_server($server) {
	$domains = $server['domains'];

	$api = new kolab_api_client($server);

	if ($api->establish_connection() == null) {
		return false;
	}

	// fetch the email addresses for each domain
	$mailaccounts = array();
	foreach ($domains as $domain) {
		if ($api->select_domain($domain)) {
			$mailaccounts = array_merge($mailaccounts, $api->get_email_addresses(array('mail', 'cn', 'uid', 'entrydn')));
		}
	}

	// delete 10 user accounts
	$api->select_domain('dev.tbits.net');
	$deleted = 0;
	foreach ($mailaccounts as $email => $userdetails) {
		if ($userdetails['domain'] == 'dev.tbits.net' && strpos($email, "john.doe") !== false && $deleted < 10) {
			// delete this user
			echo "deleting ".$userdetails['entrydn']."\n";
			if (!$api->user_delete($userdetails['entrydn'])) {
				die("cannot delete user\n");
			}
			$deleted ++;
		}
	}

	// add 3 users
	$api->select_domain('dev.tbits.net');
	for ($i = 0; $i < 3; $i++) {
		echo "adding user $i\n";
		if (!$api->user_add(array('givenname' => 'John', 'sn' => 'Doe', 'preferredlanguage' => 'en_US', 'ou' => 'ou=People,dc=dev,dc=tbits,dc=net'))) {
			die("cannot add user\n");
		}
	}

	// update the last login time
	foreach ($mailaccounts as $email => $userdetails) {

		echo $email." ".$userdetails['entrydn']."\n";

		if (($userobj = $api->user_info($userdetails['entrydn'])) !== false) {
			//print_r($userobj);
			$api->select_domain($userdetails['domain']);
			$userarray = (array)$userobj;
			$userarray['tbitskolablastlogin'] = date("U");
			$api->user_edit($userdetails['entrydn'], $userarray);
		}
	}
}

foreach ($servers as $servername => $server) {
	process_server($server);
}

?>

