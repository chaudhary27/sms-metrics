module Outputs
  require 'csv'
  class Metrics
    attr_accessor :keen, :incoming_sms

    def initialize
      @keen = Weeels::Keen.new.client
    end

    def incoming_sms_responses(end_date)
      CSV.open("sms_analysis.csv", "wb") do |csv|
        csv << ["Timestamp_receive", "Name_rec", "sms_body", "msgs_sent_count", "msgs_sent_timestamp", "msgs_sent_body"]
        negative_responses = ["stop", "unsubscribe", "remove", "STOP", "Stop", "UNSUBSCRIBE", "REMOVE", "delete", "wrong number", "off", "do not", "spam", "who is this?"]
        negative_responses.each do |keyword|
          @incoming_sms = keen_query_1((end_date-7.day).to_time, (end_date).to_time, 'incoming_sms', keyword)
          @incoming_sms.each do |sms|
            end_date = Time.parse(sms["keen"]["timestamp"])
            if sms["from_user"] == nil
              name = "no_name_avail"
              @root_msgs = keen_query_2((end_date-7.day).to_time, end_date, 'sent_sms_message')
              @root_msgs_count = @root_msgs.count
              @root_msgs.each_with_index do |msg, index|
                if index == 0
                  csv << ["#{sms["keen"]["timestamp"]}", "#{name}", "#{sms["body"]}", "#{@root_msgs_count}",
                  "#{msg["keen"]["timestamp"]}", "#{msg["message"]}"]
                else
                  csv << ["", "", "", "","#{msg["keen"]["timestamp"]}", "#{msg["message"]}"]
                end
              end
            else
              user_id = sms["from_user"]["ID"]
              @root_msgs = keen_query((end_date-7.day).to_time, end_date, 'sent_sms_message', user_id)
              @root_msgs_count = @root_msgs.count
              @root_msgs.each_with_index do |msg, index|
                if index == 0
                  csv << ["#{sms["keen"]["timestamp"]}", "#{sms["from_user"]["Name"]}", "#{sms["body"]}", "#{@root_msgs_count}",
                  "#{msg["keen"]["timestamp"]}", "#{msg["message"]}"]
                else
                  csv << ["", "", "", "","#{msg["keen"]["timestamp"]}", "#{msg["message"]}"]
                end
              end
            end
          end
        end
      end
    end

    def keen_query_1(start_time, end_time, collection_name, keyword)
      keen.extraction(collection_name, {
        timeframe: {
          :start => keen_timestamp(start_time),
          :end => keen_timestamp(end_time)
        }, filters: [{
          "property_name" => "params.body",
          "operator" => "contains",
          "property_value" => keyword
        }]
      }, {
        method: :post,
        max_age: 100000
      })
    end

    def keen_query (start_time, end_time, collection_name, from_user_id)
      keen.extraction(collection_name, {
        timeframe: {
          :start => keen_timestamp(start_time),
          :end => keen_timestamp(end_time)
        }, filters: [{
          "property_name" => "to_user.ID",
          "operator" => "eq",
          "property_value" => from_user_id
        }]
      }, {
        method: :post,
        max_age: 100000
      })
    end

    def keen_query_2 (start_time, end_time, collection_name)
      keen.extraction(collection_name, {
        timeframe: {
          :start => keen_timestamp(start_time),
          :end => keen_timestamp(end_time)
        }
      }, {
        method: :post,
        max_age: 100000
      })
    end

    def net_promoter_score(end_date)
      CSV.open("NPS_average.csv", "ab") do |csv|
        #csv << ["Date", "Average_NPS_Score"]
        @nps_scores = []
        @feed_back_sms = keen_query_3((end_date-7.day).to_time, (end_date).to_time, 'feedback_given')
        @feed_back_sms.each do |sms|
          @nps = sms["feedback"]["score"]
          @nps_scores << @nps
        end
        avg = @nps_scores.inject(0.0){|sum, el| sum + el} / @nps_scores.size
        csv << ["#{Date.today}", "#{avg}"]
            #@nps_score_ << @nps_score
            #puts @nps_score_
            #if @nps_score != nil && (@nps_score >=0 || @nps_score <=10)
            #  @nps_score_ << @nps_score
            #end
            #nps_avg = keen_query_3((end_date-1.day).to_time, (end_date).to_time, 'incoming_sms')
            #csv << ["#{body}"]
          #end
        #end
        #puts @nps_score_
        #@avg = @nps_score_.inject(0.0){|sum, el| sum + el} / @nps_score_.size
        #  csv << ["#{Date.today}", "#{@feed_back_sms}"]
      end
    end

    def keen_query_3(start_time, end_time, collection_name)
      keen.extraction(collection_name, {
        timeframe: {
          :start => keen_timestamp(start_time),
          :end => keen_timestamp(end_time)
        }
      }, {
        method: :post,
        max_age: 100000
      })
    end

    def keen_query_4(start_time, end_time, collection_name)
      keen.extraction(collection_name, {
        timeframe: {
          :start => keen_timestamp(start_time),
          :end => keen_timestamp(end_time)
        }
      }, {
        method: :post,
        max_age: 100000
      })
    end
=begin
    , filters: [{
      "property_name" => "params.body",
      "operator" => "gte",
      "property_value" => "8"
    }]
=end
    def keen_timestamp(t)
      t.iso8601(3)
    end
  end
end
