# Verify a computer exists in Landscape using a pre-issued token.
#
# Usage:
# class { 'landscape::example::verify_computer_with_token':
#   api_url   => 'https://landscape.example.com',
#   api_token => Sensitive('replace-with-jwt'),
#   computer_id => 23,
# }
class landscape::example::verify_computer_with_token (
  String $api_url,
  Sensitive[String] $api_token,
  Integer $computer_id,
) {
  landscape_computer { "${computer_id}":
    ensure    => present,
    api_url   => $api_url,
    api_token => $api_token.unwrap,
  }
}
