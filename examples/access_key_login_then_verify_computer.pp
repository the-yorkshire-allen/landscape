# Validate access-key login first, then verify a computer exists.
#
# Usage:
# class { 'landscape::example::access_key_login_then_verify_computer':
#   api_url     => 'https://landscape.example.com',
#   access_key  => Sensitive('replace-with-access-key'),
#   secret_key  => Sensitive('replace-with-secret-key'),
#   token_file  => '/run/landscape.jwt',
#   computer_id => 23,
# }
class landscape::example::access_key_login_then_verify_computer (
  String $api_url,
  Sensitive[String] $access_key,
  Sensitive[String] $secret_key,
  String $token_file = '/run/landscape.jwt',
  Integer $computer_id,
) {
  landscape_login { 'landscape-login-check-access-key':
    ensure     => present,
    api_url    => $api_url,
    access_key => $access_key.unwrap,
    secret_key => $secret_key.unwrap,
    token_file => $token_file,
  }

  landscape_computer { "${computer_id}":
    ensure         => present,
    api_url        => $api_url,
    api_token_file => $token_file,
    require        => Landscape_login['landscape-login-check-access-key'],
  }
}
