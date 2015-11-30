module Weeels
  class Locations
    attr_reader :api_client
    
    def initialize
      @api_client = Weeels.api_client
    end

    def by_name(name)
      api_client.request('/locations/by_name.json', name: name)
    end
  end
end