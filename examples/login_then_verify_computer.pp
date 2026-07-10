# Validate login credentials first, then verify a computer exists.
#
# This example writes the JWT from landscape_login to a local file, then
# landscape_computer reads it via api_token_file.
#
# Usage:
# class { 'landscape::example::login_then_verify_computer':
#   api_url      => 'https://landscape.example.com',
#   login_email  => 'john@example.com',
#   login_password => Sensitive('replace-with-password'),
#   account      => 'onward',
#   token_file   => '/run/landscape.jwt',
#   computer_id  => 23,
# }
class landscape::example::login_then_verify_computer (
  String $api_url,
  String $login_email,
  Sensitive[String] $login_password,
  Optional[String] $account = undef,
  String $token_file = '/run/landscape.jwt',
  Integer $computer_id,
) {
  landscape_login { 'landscape-login-check':
    ensure   => present,
    api_url  => $api_url,
    email    => $login_email,
    password => $login_password.unwrap,
    account  => $account,
    token_file => $token_file,
  }

  landscape_computer { "${computer_id}":
    ensure         => present,
    api_url        => $api_url,
    api_token_file => $token_file,
    require        => Landscape_login['landscape-login-check'],
  }
}
