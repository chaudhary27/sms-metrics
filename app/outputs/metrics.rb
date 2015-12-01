module Outputs
  require 'csv'
  class Metrics
    attr_accessor :keen

    def initialize
        @keen = Weeels::Keen.new.client
    end
=begin
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
=end

    def incoming_sms_responses(start_date)
      CSV.open("incoming_sms.csv", "wb") do |csv|
        csv << ["Date", "incoming_sms"]
        while start_date < Date.today
          @incoming_sms = keen_query_1(start_date.to_time, (start_date+1.day).to_time, 'incoming_sms')
          #@incoming_sms.each do |sms|
          #  body = sms["params.body"]
          #  if (body = 'Unsubscribe' || body = "UNSUBSCRIBE")
          csv << ["#{start_date}", "#{@incoming_sms}"]
          #  end
          #end
          start_date = start_date+1.day
        end
      end
    end

    # takes array of user_ids and timestamps
    # returns last_msg_sent to that user_id and that timestamp
    #
    def last_msg_sent_to_user_id_at_time(user_ids, timestamps)
      user_ids.each do |user_id|
        timestamps.each do |timestamp|
          last_msg = Weeels::ClassName.(user_id, timestamp)
      end
    end

    def keen_query_1(start_time, end_time, collection_name)
      keen.count(collection_name, {
        timeframe: {
          :start => keen_timestamp(start_time),
          :end => keen_timestamp(end_time)
        }
      }, {
        method: :post,
        max_age: 100000
      })
    end

    # Takes a user_id and a timestamp
    # Asks for last text msg send to that user_id & also provides # of sms sent to that user (marketing_only)

=begin
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
=end
    def keen_timestamp(t)
      t.iso8601(3)
    end
  end
end
