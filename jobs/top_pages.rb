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

SCHEDULER.every '150s', :first_in => 0 do

  # Request a token for our service account
  client.authorization.fetch_access_token!

  # Get the analytics API
  analytics = client.discovered_api('analytics','v3')

  # Execute the query
  response = client.execute(:api_method => analytics.data.realtime.get, :parameters => {
    'ids' => "ga:" + profile_id,
    'dimensions' => 'rt:pagePath, rt:pageTitle',
    'metrics' => "rt:activeUsers",
  })

  top_pages  = response.data.rows.sort { |x, y| y[2] <=> x[2]}
  formatted_top_pages = top_pages.first(5).collect{ |path, title, count| { label: path, value: count.to_i}}

  # Update the dashboard
  send_event('top_pages', { items: formatted_top_pages}) 

end
