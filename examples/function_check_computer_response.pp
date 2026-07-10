# Example: call landscape::computer_check() and inspect JSON response data in Puppet code.
#
# NOTE: This function runs during catalog compilation (on Puppet Server), not on the agent.
# Ensure the Puppet Server can reach Landscape and access the token file if used.
class landscape::example::function_check_computer_response (
  Integer $computer_id,
  String $api_url,
  Optional[String] $api_token = undef,
  Optional[String] $api_token_file = '/run/landscape.jwt',
) {
  $result = landscape::computer_check($computer_id, $api_url, $api_token, $api_token_file)

  if $result['exists'] {
    notice("Landscape computer ${computer_id} exists; hostname=${$result['data']['hostname']}")
  } else {
    warning("Landscape computer ${computer_id} not found (status=${$result['status_code']})")
  }

  # Example check on returned JSON fields:
  if $result['exists'] and $result['data']['reboot_required_flag'] == true {
    warning("Computer ${computer_id} requires reboot")
  }
}
