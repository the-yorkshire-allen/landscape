# Validate login with a 1-minute token lifetime, then verify a computer exists.
#
# Usage:
# class { 'landscape::example::login_with_1_minute_expiry_then_verify_computer':
#   api_url        => 'https://landscape.example.com',
#   login_email    => 'john@example.com',
#   login_password => Sensitive('replace-with-password'),
#   account        => 'onward',
#   token_file     => '/run/landscape.jwt',
#   computer_id    => 23,
# }
class landscape::example::login_with_1_minute_expiry_then_verify_computer (
  String $api_url,
  String $login_email,
  Sensitive[String] $login_password,
  Optional[String] $account = undef,
  String $token_file = '/run/landscape.jwt',
  Integer $computer_id,
) {
  landscape_login { 'landscape-login-check-1-minute-expiry':
    ensure         => present,
    api_url        => $api_url,
    email          => $login_email,
    password       => $login_password.unwrap,
    account        => $account,
    expiry_minutes => 1,
    token_file     => $token_file,
  }

  landscape_computer { "${computer_id}":
    ensure         => present,
    api_url        => $api_url,
    api_token_file => $token_file,
    require        => Landscape_login['landscape-login-check-1-minute-expiry'],
  }
}
