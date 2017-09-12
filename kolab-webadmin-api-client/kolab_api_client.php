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

class kolab_api_client
{
	private $ch = null;
	private $server = null;
	private $current_domain = null;

	function __construct($server) {
		$this->server = $server;
	}

	function establish_connection() {
	global $proxy;
	global $proxyauth;
		$url=$this->server['api_url']."system.authenticate";
		$postdata =
			array(
				'username' => $this->server['username'],
				'password' => $this->server['password']
			);

		$this->ch = curl_init();

		curl_setopt($this->ch, CURLOPT_URL, $url);
		if (!empty($proxy)) {
			curl_setopt($this->ch, CURLOPT_PROXY, $proxy);
			curl_setopt($this->ch, CURLOPT_PROXYUSERPWD, $proxyauth);
		}

		if (strpos($this->server['api_url'], "localhost") !== false) {
			curl_setopt($this->ch, CURLOPT_SSL_VERIFYHOST, 0);
			curl_setopt($this->ch, CURLOPT_SSL_VERIFYPEER, 0);
		}

		curl_setopt($this->ch, CURLOPT_FOLLOWLOCATION, 1);
		curl_setopt($this->ch, CURLOPT_RETURNTRANSFER, 1);
		curl_setopt($this->ch, CURLOPT_CUSTOMREQUEST, 'POST');
		curl_setopt($this->ch, CURLOPT_POST, 1);
		curl_setopt($this->ch, CURLOPT_POSTFIELDS, json_encode($postdata));
		curl_setopt($this->ch, CURLOPT_HTTPHEADER, array('Content-Type: application/x-www-form-urlencoded'));
		curl_setopt($this->ch, CURLOPT_HEADER, 1);

		$response = curl_exec($this->ch);

		if (!$response) {
			die ("establish_connection: ".curl_error($this->ch)."\n");
		}

		list($header, $body) = explode("\r\n\r\n", $response, 2);
		$json = json_decode($body);
		if ($json->status == 'OK') {
			curl_setopt($this->ch, CURLOPT_HTTPHEADER, array('Content-Type: application/x-www-form-urlencoded', 'X-Session-Token: '.$json->result->session_token));
			return $this->ch;
		}
		echo ("cannot authenticate with Kolab Webadmin API\n");
		return null;
	}

	function select_domain($domain) {
		if ($this->current_domain != null && $this->current_domain == $domain) {
			return true;
		}

		$url=$this->server['api_url']."system.select_domain";
		curl_setopt($this->ch, CURLOPT_URL, $url."?domain=$domain");
		curl_setopt($this->ch, CURLOPT_CUSTOMREQUEST, 'GET');
		curl_setopt($this->ch, CURLOPT_POST, 0);

		$response = curl_exec($this->ch);
		list($header, $body) = explode("\r\n\r\n", $response, 2);
		$json = json_decode($body);
		if ($json->status == 'OK') {
			$this->current_domain = $domain;
			return true;
		}
		echo ("cannot select_domain: \n".$response."\n\n");
		return false;
	}

	function get_email_addresses($attributes) {
		// see https://cgit.kolab.org/webadmin/tree/lib/api/kolab_api_service_users.php#n68
		$url=$this->server['api_url']."users.list";
		$postdata =
			array(
				'attributes' => $attributes,
			);

		curl_setopt($this->ch, CURLOPT_URL, $url);
		curl_setopt($this->ch, CURLOPT_CUSTOMREQUEST, 'POST');
		curl_setopt($this->ch, CURLOPT_POST, 1);
		curl_setopt($this->ch, CURLOPT_POSTFIELDS, json_encode($postdata));

		$response = curl_exec($this->ch);
		list($header, $body) = explode("\r\n\r\n", $response, 2);
		$json = json_decode($body);
		if ($json->status == 'OK') {
			$mailaccounts = array();
			foreach ($json->result->list as $key => $obj) {
				if (empty($obj->mail)) {
					continue;
				}
				if (in_array('userpassword', $attributes) && empty($obj->userpassword)) {
					echo "warning: empty userpassword for ".$obj->mail."\n";
					continue;
				}
				// echo $key." ".$obj->mail." ". $obj->userpassword."\n";
				$mailaccounts[$obj->mail] = array();
				if (in_array('userpassword', $attributes)) {
					$mailaccounts[$obj->mail]['userpassword'] = $obj->userpassword;
				}
				if (in_array('cn', $attributes)) {
					$mailaccounts[$obj->mail]['cn'] = $obj->cn;
				}
				if (in_array('uid', $attributes)) {
					$mailaccounts[$obj->mail]['uid'] = $obj->uid;
				}
				if (in_array('entrydn', $attributes)) {
					$mailaccounts[$obj->mail]['entrydn'] = $obj->entrydn;
				}
				$mailaccounts[$obj->mail]['domain'] = $this->current_domain;
			}
			return $mailaccounts;
		}
		echo ("cannot get_email_addresses: \n".$response."\n\n");
	}

	function user_info($id) {
		// see https://cgit.kolab.org/webadmin/tree/lib/api/kolab_api_service_user.php#n170
		$url=$this->server['api_url']."user.info?id=".urlencode($id);

		curl_setopt($this->ch, CURLOPT_URL, $url);
		// force GET
		curl_setopt($this->ch, CURLOPT_CUSTOMREQUEST, 'GET');

		$response = curl_exec($this->ch);
		// bug in PHP 5.4: https://stackoverflow.com/questions/4163865/how-to-reset-curlopt-customrequest
		// curl_setopt($this->ch, CURLOPT_CUSTOMREQUEST, null);
		curl_setopt($this->ch, CURLOPT_CUSTOMREQUEST, 'POST');

		list($header, $body) = explode("\r\n\r\n", $response, 2);
		$json = json_decode($body);
		// echo ("test in user_info: \n".$response."\n\n");
		if ($json->status == 'OK') {
			return $json->result;
		}
		echo ("problem in user_info: \n".$response."\n\n");
		return false;
	}

	function user_edit($id, $attributes) {
		// see https://cgit.kolab.org/webadmin/tree/lib/api/kolab_api_service_user.php#n130
		$url=$this->server['api_url']."user.edit";

		$attributes['id'] = $id;
		$attributes['type_id'] = 1;
		unset($attributes['entrydn']);

		curl_setopt($this->ch, CURLOPT_URL, $url);
		curl_setopt($this->ch, CURLOPT_CUSTOMREQUEST, 'POST');
		curl_setopt($this->ch, CURLOPT_POST, 1);
		curl_setopt($this->ch, CURLOPT_POSTFIELDS, json_encode($attributes));

		$response = curl_exec($this->ch);
		list($header, $body) = explode("\r\n\r\n", $response, 2);
		$json = json_decode($body);

		if ($json->status == 'OK') {
			return true;
		}

		echo ("problem in user_edit: \n".$response."\n\n");

		return false;
	}

	function user_add($attributes) {
		$url=$this->server['api_url']."user.add";

		$postdata =
			array(
				'object_type' => 'user',
				'type_id' => 1
				);

		$postdata = array_merge($postdata, $attributes);

		curl_setopt($this->ch, CURLOPT_URL, $url);
		curl_setopt($this->ch, CURLOPT_CUSTOMREQUEST, 'POST');
		curl_setopt($this->ch, CURLOPT_POST, 1);
		curl_setopt($this->ch, CURLOPT_POSTFIELDS, json_encode($postdata));

		$response = curl_exec($this->ch);
		list($header, $body) = explode("\r\n\r\n", $response, 2);
		$json = json_decode($body);

		if ($json->status == 'OK') {
			return true;
		}

		echo ("problem in user_add: \n".$response."\n\n");
		return false;
	}

	function user_delete($id) {
		$url=$this->server['api_url']."user.delete";

		curl_setopt($this->ch, CURLOPT_URL, $url);
		curl_setopt($this->ch, CURLOPT_CUSTOMREQUEST, 'POST');
		curl_setopt($this->ch, CURLOPT_POST, 1);
		curl_setopt($this->ch, CURLOPT_POSTFIELDS, json_encode(array('id' => $id)));

		$response = curl_exec($this->ch);
		list($header, $body) = explode("\r\n\r\n", $response, 2);
		$json = json_decode($body);

		if ($json->status == 'OK') {
			return true;
		}

		echo ("problem in user_delete: \n".$response."\n\n");
		return false;
	}

	function domain_add($domain) {
		$url=$this->server['api_url']."domain.add";

		curl_setopt($this->ch, CURLOPT_URL, $url);
		curl_setopt($this->ch, CURLOPT_CUSTOMREQUEST, 'POST');
		curl_setopt($this->ch, CURLOPT_POST, 1);
		curl_setopt($this->ch, CURLOPT_POSTFIELDS, json_encode(array('associateddomain' => $domain)));

		$response = curl_exec($this->ch);
		list($header, $body) = explode("\r\n\r\n", $response, 2);
		$json = json_decode($body);

		if ($json->status == 'OK') {
			return true;
		}

		echo ("problem in domain_add: \n".$response."\n\n");
		return false;
	}
}

?>

