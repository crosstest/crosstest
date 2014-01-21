RSpec.configure do |c|
  c.after(:each) { auto_teardown }
end

def auth_token
  @auth_token ||= Pacto::ValidationRegistry.instance.validations.map do | val |
    token = val.request.headers['X-Auth-Token']
  end.compact.reject(&:empty?).first
end

def auto_teardown
  # HACK: This should be simplified and moved to Pacto
  

  created_servers = auto_find '/v2/:account_id/servers'
  auto_delete created_servers, auth_token
end

def auto_find uri_pattern
  # Pacto doesn't find services in ORD if it is only validating DFW...
  matches = Pacto::ValidationRegistry.instance.validations.find_all {|validation|
    validation.contract && validation.contract.request.path == uri_pattern
  }

  matches.map do | match |
    Addressable::URI.parse match.response.headers['Location']
  end
end

def auto_delete uris, auth_token
  uris.group_by(&:site).each do | site, uris |
    connection = Excon.new(site)
    uris.each do | uri |
      puts "Removing #{uri}"
      connection.delete(:path => uri.path,
        :debug_request => true,
        :debug_response => true,
        :expects => [204],
        :headers => {
          "User-Agent" => "fog/1.18.0",
          "Content-Type" => "application/json",
          "Accept" => "application/json",
          "X-Auth-Token" => auth_token
        }
      )
    end
  end
end