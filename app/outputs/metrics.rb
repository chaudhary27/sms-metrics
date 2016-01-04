module Outputs
  require 'csv'
  class Metrics
    attr_accessor :keen

    def initialize
        @keen = Weeels::Keen.new.client
    end

    def incoming_sms_responses(start_date)
      CSV.open("incoming_sms.csv", "wb") do |csv|
        csv << ["Date", "incoming_sms"]
        while start_date < Date.today
          @incoming_sms = keen_query_1(start_date.to_time, (start_date+1.day).to_time, 'incoming_sms')
          #@incoming_sms_Unsub = keen_query_2(start_date.to_time, (start_date+1.day).to_time, 'incoming_sms')
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

    # START WITH
    # filter using keens filter to unsub or stop
    # research how we can use keens regex matching etc.

    # takes array of user_ids and timestamps
    # returns last_msg_sent to that user_id and that timestamp
    def sent_sms_message(start_date, user_id)
      while start_date < Date.today
          @last_msg = keen_query(start_date.to_time, (start_date+1.day).to_time, 'sent_sms_message', user_id)
          start_date = start_date+1.day
      end
      puts @last_msg
    end

    def keen_query (start_time, end_time, collection_name, user_id)
      keen.extraction(collection_name, {
        timeframe: {
          :start => keen_timestamp(start_time),
          :end => keen_timestamp(end_time)
        }, filters: [{
          "property_name" => "ID",
          "operator" => "eq",
          "property_value" => user_id
        }]
      }, {
        method: :post,
        max_age: 100000
      })
    end

    def keen_query_1(start_time, end_time, collection_name)
      keen.extraction(collection_name, {
        timeframe: {
          :start => keen_timestamp(start_time),
          :end => keen_timestamp(end_time)
        }, filters: [{
          "property_name" => "params.body",
          "operator" => "contains",
          "property_value" => "UNSUBSCRIBE"
        }]
      }, {
        method: :post,
        max_age: 100000
      })
    end

    def keen_query_2(start_time, end_time, collection_name)
      keen.extraction(collection_name, {
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
