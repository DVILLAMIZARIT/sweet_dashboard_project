require 'google/api_client'
require 'date'
 
# Update these to match your own apps credentials
service_account_email = 'SERVICE_ACCOUNT_EMAIL@developer.gserviceaccount.com' # Email of service account
key_file = 'PRIVATE_KEY.p12' # File containing your private key
key_secret = 'PRIVATE_KEY_PASSWORD' # Password to unlock private key
profile_id = 'ANALYTICS_VIEW_ID' # Analytics View ID.
 
# Get the Google API client
client = Google::APIClient.new(
  :application_name => 'Unience Dashing Client', 
  :application_version => '0.01'
)

visitors = []

# Load your credentials for the service account
key = Google::APIClient::KeyUtils.load_from_pkcs12(key_file, key_secret)
client.authorization = Signet::OAuth2::Client.new(
  :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
  :audience => 'https://accounts.google.com/o/oauth2/token',
  :scope => 'https://www.googleapis.com/auth/analytics.readonly',
  :issuer => service_account_email,
  :signing_key => key)

# Start the scheduler
current_visitors = 0

SCHEDULER.every '10s', :first_in => 0 do

  # Request a token for our service account
  client.authorization.fetch_access_token!

  # Get the analytics API
  analytics = client.discovered_api('analytics','v3')

  # Execute the query
  response = client.execute(:api_method => analytics.data.realtime.get, :parameters => {
    'ids' => "ga:" + profile_id,
    'dimensions' => 'rt:deviceCategory',
    'metrics' => "rt:activeUsers",
  })

  last_visitors = current_visitors
  puts response.body
  current_visitors = response.data.totalsForAllResults["rt:activeUsers"].to_i

  # Update the dashboard
  send_event('visitor_count_real_time', { current: current_visitors, last: last_visitors }) 
  
  device_category = response.data.rows.collect{ |device, count| { label: device, value: count.to_i}}

  send_event('device_category', { value: device_category })

end
