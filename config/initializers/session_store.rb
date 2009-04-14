# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_haltr_session',
  :secret      => 'a68e3a2daa6ad19530a08c9ba420a2f9ffd26584631920a0024e421dce4a7aee8e52433d6d22842123ed836bb912d802b3c203624d5b7b66ad6276c9de919973'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
