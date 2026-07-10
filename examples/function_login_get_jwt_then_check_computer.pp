# Example: get JWT into a Puppet variable and use it directly.
#
# NOTE: This function runs during catalog compilation (on Puppet Server), not on
# the agent. Puppet Server must be able to reach Landscape.
class landscape::example::function_login_get_jwt_then_check_computer (
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
    5,
  )

  $computer = landscape::computer_check($computer_id, $api_url, $jwt)

  if $computer['exists'] {
    notice("Computer ${computer_id} exists with hostname=${$computer['data']['hostname']}")
  } else {
    warning("Computer ${computer_id} not found")
  }
}
