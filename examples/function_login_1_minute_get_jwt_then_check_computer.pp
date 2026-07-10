# Example: get JWT with 1-minute expiry via login function, then check computer JSON.
class landscape::example::function_login_1_minute_get_jwt_then_check_computer (
  String $api_url,
  String $login_email,
  Sensitive[String] $login_password,
  Optional[String] $account = undef,
  Integer $computer_id,
) {
  $jwt = landscape::login_jwt(
    $api_url,
    $login_email,
    $login_password.unwrap,
    undef,
    $account,
    1,
  )

  $computer = landscape::computer_check($computer_id, $api_url, $jwt)

  if $computer['exists'] and $computer['data']['reboot_required_flag'] == true {
    warning("Computer ${computer_id} requires reboot")
  }

  if $computer['exists'] {
    notice("Computer ${computer_id} exists")
  } else {
    warning("Computer ${computer_id} not found")
  }
}
