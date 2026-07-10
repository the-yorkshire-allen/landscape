# Full example: access-key login, token handoff, then function-based JSON check.
#
# This demonstrates:
# 1) landscape_login authenticates via /login/access-key
# 2) JWT is written to token_file
# 3) landscape::computer_check() fetches computer JSON into a Puppet variable
# 4) Puppet conditionals inspect fields from the response
class landscape::example::access_key_login_then_function_check_computer (
  String $api_url,
  Sensitive[String] $access_key,
  Sensitive[String] $secret_key,
  Integer $computer_id,
  String $token_file = '/run/landscape.jwt',
) {
  landscape_login { 'landscape-login-access-key-for-function-check':
    ensure         => present,
    api_url        => $api_url,
    access_key     => $access_key.unwrap,
    secret_key     => $secret_key.unwrap,
    expiry_minutes => 5,
    token_file     => $token_file,
  }

  # Pull computer response JSON into a Puppet variable as a structured Hash.
  $computer_result = landscape::computer_check($computer_id, $api_url, undef, $token_file)

  if $computer_result['exists'] {
    notify { "landscape-computer-${computer_id}-found":
      message => "Found computer ${computer_id} hostname=${$computer_result['data']['hostname']}",
    }

    if $computer_result['data']['reboot_required_flag'] == true {
      warning("Computer ${computer_id} requires reboot according to Landscape")
    }
  } else {
    warning("Computer ${computer_id} not found in Landscape (status=${$computer_result['status_code']})")
  }

}
