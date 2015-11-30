module Weeels
  class BeaconPresences
    attr_reader :api_client, :location, :entered_at, :left_at, :source, :last_check_in

    @time_window_request_cache = {}

    def self.api_client
      @api_client = Weeels.api_client
    end

    def self.for_location(id)
      api_client.request('/beacon_presences/at_location.json', location_id: id, include_all: true).map do |json|
        new(json)
      end
    end

    def self.for_time_window(start_time, end_time, location_id)
      response = get_from_time_window_request_cache(start_time, end_time, location_id) ||
                  for_time_window_request(start_time, end_time, location_id)

      response.map do |json|
        new(json)
      end
    end

    def self.for_time_window_request(start_time, end_time, location_id)
      res = api_client.request(
        '/beacon_presences/for_time_window.json',
        {
          location_id: location_id,
          start_time: start_time,
          end_time: end_time
        }
      )

      cache_for_time_window_request(start_time, end_time, location_id, res)
      res
    end

    def self.get_from_time_window_request_cache(start_time, end_time, location_id)
      key = time_window_request_cache_key(start_time, end_time, location_id)
      @time_window_request_cache[key]
    end

    def self.cache_for_time_window_request(start_time, end_time, location_id, response)
      key = time_window_request_cache_key(start_time, end_time, location_id)
      @time_window_request_cache[key] = response
    end

    def self.time_window_request_cache_key(start_time, end_time, location_id)
      "#{start_time.to_s}:#{end_time.to_s}:#{location_id}"
    end

    def initialize(json)
      @location = json["location"]
      @entered_at = time_from_ms(json["entered_at"])
      @left_at = time_from_ms(json["left_at"])
      @last_check_in = time_from_ms(json["last_check_in"])
      if @left_at == nil
        @left_at = @last_check_in
      end
      @source = json
    end

    def time_from_ms(ms)
      return nil unless ms
      Time.at(ms/1000)
    end
  end
end
