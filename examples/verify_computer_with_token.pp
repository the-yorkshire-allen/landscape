# Verify a computer exists in Landscape using a pre-issued token.
#
# Supply these with Hiera or class parameters in real usage.
$landscape_api_url   = 'https://landscape.example.com'
$landscape_api_token = 'replace-with-jwt'
$computer_id         = 23

landscape_computer { $computer_id:
  ensure    => present,
  api_url   => $landscape_api_url,
  api_token => $landscape_api_token,
}
