# Validate login credentials first, then verify a computer exists.
#
# NOTE: landscape_login validates credentials but does not export a token value
# into other resources. Provide api_token separately (for example from Hiera or
# from an external token-fetch step).
$landscape_api_url   = 'https://landscape.example.com'
$landscape_api_token = 'replace-with-jwt'
$computer_id         = 23

landscape_login { 'landscape-login-check':
  ensure   => present,
  api_url  => $landscape_api_url,
  email    => 'john@example.com',
  password => 'replace-with-password',
  account  => 'onward',
}

landscape_computer { $computer_id:
  ensure    => present,
  api_url   => $landscape_api_url,
  api_token => $landscape_api_token,
  require   => Landscape_login['landscape-login-check'],
}
