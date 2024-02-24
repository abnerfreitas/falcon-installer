#!/bin/bash

# Constants for API endpoint and port
CROWDSTRIKE_API_ENDPOINT="https://api.crowdstrike.com"
FALCON_SERVICE_PORT="8080"

# Function to send a GET request and return the response
send_request () {
  local url="$CROWDSTRIKE_API_ENDPOINT/$1"
  curl -k -s -X GET "$url" -H "Authorization: Bearer $CROWDSTRIKE_API_KEY"
}

# Function to validate communication between Falcon Service and CrowdStrike API
validate_communication () {
  # Get Falcon integration ID from the API
  local falcon_integration_id=$(send_request "integrations/v1/falcon-vm/accept-invite")
  if [[ -z $falcon_integration_id ]]; then
    echo "Failed to get Falcon integration ID."
    exit 1
  fi

  # Build Falcon Service URL
  local falcon_service_url="http://localhost:$FALCON_SERVICE_PORT/v1/integrations/$falcon_integration_id"

  # Send request to Falcon Service
  local response=$(curl -k -s "$falcon_service_url")
  echo "$response"

  # Check response for success
  if [[ $response != "OK" ]]; then
    echo "Failed to communicate with Falcon Service."
    exit 1
  fi

  # Success message
  echo "Successfully validated communication between Falcon Service and CrowdStrike."
}

# Call the validation function
validate_communication