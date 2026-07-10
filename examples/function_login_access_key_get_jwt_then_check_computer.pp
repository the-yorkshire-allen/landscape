# Example: get JWT via access-key login function, then check computer JSON.
class landscape::example::function_login_access_key_get_jwt_then_check_computer (
  String $api_url,
  Sensitive[String] $access_key,
  Sensitive[String] $secret_key,
  Integer $computer_id,
) {
  $jwt = landscape::login_jwt(
    $api_url,
    undef,
    undef,
    undef,
    undef,
    5,
    $access_key.unwrap,
    $secret_key.unwrap,
  )

  $computer = landscape::computer_check($computer_id, $api_url, $jwt)

  if $computer['exists'] {
    notice("Computer ${computer_id} exists with hostname=${$computer['data']['hostname']}")
  } else {
    warning("Computer ${computer_id} not found (status=${$computer['status_code']})")
  }
}
