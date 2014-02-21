describe 'Cloud Files', :markdown =>
  """
  In this section we'll cover Cloud Files.  We'll start with a few simple services.  In the final example for this section, we will upload static assets to a CDN-enabled Cloud Files container that will be used by our sample application.
  """ do
  file = build :file
  env = standard_env_vars.merge(
    'TEST_DIRECTORY' => file.directory.key,
    'TEST_FILE' => file.key
  )

  vars = standard_env_vars
  validate_challenge "List Containers", """
  Use the SDK to list your existing cloud Cloud Files containers.
  """, vars, [] do |success|
    # Assertions
    expect(Pacto).to have_validated(:get, /\/v1\/[\w-]+/) #.twice
    expect(Pacto).to_not have_failed_validations
    expect(Pacto).to_not have_unmatched_requests
  end

  validate_challenge "Get object metadata", """
  Now, use the SDK to retrieve a file from Cloud Files.
  """, env, [] do
    # Will use Service nicknames or nicer URI templates in the future
    uri_pattern = /\/v1\/[\w-]+\/[\w-]+\/[\w-]+/
    expect(Pacto).to have_validated(:head, uri_pattern)
    expect(Pacto).to_not have_validated(:get, uri_pattern)
  end

  validate_challenge "Upload a single file", """
  Now, let's upload logo.png to Cloud Files so we can start building a website.
  """, env, [] do
    pending
  end

  validate_challenge "Upload static assets", """
  Finally, let's upload static assets (javascript, css, images, fonts) for a website.
  """, env, [] do
    pending
  end

  validate_challenge "Upload static assets", """
  Let's enable the CDN for our assets.
  """, env, [] do
    pending
  end

end