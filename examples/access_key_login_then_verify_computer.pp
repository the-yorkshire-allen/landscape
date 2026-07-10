# Validate access-key login first, then verify a computer exists.
#
# The verification resource still needs its own api_token input today.
$landscape_api_url   = 'https://landscape.example.com'
$landscape_api_token = 'replace-with-jwt'
$computer_id         = 23

landscape_login { 'landscape-login-check-access-key':
  ensure     => present,
  api_url    => $landscape_api_url,
  access_key => 'replace-with-access-key',
  secret_key => 'replace-with-secret-key',
}

landscape_computer { $computer_id:
  ensure    => present,
  api_url   => $landscape_api_url,
  api_token => $landscape_api_token,
  require   => Landscape_login['landscape-login-check-access-key'],
}
