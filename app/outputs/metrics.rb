module Outputs
  require 'csv'
  class Metrics
    attr_accessor :keen

    def initialize
        @keen = Weeels::Keen.new.client
    end

    # takes a start_date and taxiline as arguments
    # looks for matches and requests for a each day
    # return results for a range of days until today
    def req_match(start_date, taxi_line)
        CSV.open("remat.csv", "wb") do |csv|
            csv << ["Date", "Requests", "Matches"]
            while start_date < Date.today
                @requests = keen_query(start_date.to_time,(start_date+1.day).to_time,'ride_request',taxi_line)
                @matches = keen_query(start_date.to_time,(start_date+1.day).to_time,'match_fee_charged',taxi_line)
                csv << ["#{start_date}", "#{@requests}", "#{@matches}"]
                start_date = start_date+1.day
            end
        end
    end

    def incoming_sms_responses(start_date)
      CSV.open("incoming_sms.csv", "wb") do |csv|
        csv << ["Date", "incoming_sms"]
        while start_date < Date.today
          @incoming_sms = keen_query_1(start_date.to_time, (start_date+1.day).to_time, 'incoming_sms')
          csv << ["#{start_date}", "#{@incoming_sms}"]
          start_date = start_date+1.day
        end
      end
    end

    def keen_query_1(start_time, end_time, collection_name)
      keen.count(collection_name, {
        timeframe: {
          :start => keen_timestamp(start_time),
          :end => keen_timestamp(end_time)
        }, filters: [{
          "property_name" => "params.body",
          "operator" => "contains",
          "property_value" => "Unsubscribe"
        }]
      }, {
        method: :post,
        max_age: 100000
      })
    end

    def keen_query(start_time, end_time, collection_name, taxi_line)
      keen.count(collection_name, {
        timeframe: {
          :start => keen_timestamp(start_time),
          :end => keen_timestamp(end_time)
        }, filters: [{
          "property_name" => "pickup_hub_id",
          "operator" => "eq",
          "property_value" => taxi_line.weeels_id
        }]
      }, {
        method: :post,
        max_age: 100000
      })
    end

    def keen_timestamp(t)
      t.iso8601(3)
    end
  end
end
