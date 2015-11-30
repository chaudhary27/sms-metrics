module Outputs
    require 'csv'
    class RepeatUsership
        attr_accessor :keen

        def initialize
            @keen = Weeels::Keen.new.client
        end

        def repeat_usership_1(start_date)
            CSV.open('repeat_usership.csv', "wb") do |csv|
                csv << ["USER_ID", "#_of_days"]
                #csv << ["no_of_req_grouped_by_user_id"]
                user_ids = {}
                while start_date < Date.today
                    #csv << ["#{start_date}"]
                    @requests = keen_query_1(start_date.to_time, (start_date+1.day).to_time, 'ride_request')
                    @requests.each do |hash|
                        user_id = hash["user_id"]
                        user_ids[user_id] = 0 if !user_ids[user_id]
                        user_ids[user_id] = user_ids[user_id] + 1
                    end
                    start_date = start_date+1.day
                end
                hash = user_ids.select {|user_id, count| count > 1 }
                hash.each do |user_id, count|
                    csv << [user_id, count]
                end
            end
        end

        def repeat_usership_2(start_date)
            CSV.open('repeat_usership_match_fee_charged_ride_1.csv', "wb") do |csv|
                csv << ["USER_ID", "#_of_days"]
                user_ids = {}
                while start_date < Date.today
                    @requests_1 = keen_query_2(start_date.to_time, (start_date+1.day).to_time, 'match_fee_charged')
                    @requests_2 = keen_query_3(start_date.to_time, (start_date+1.day).to_time, 'match_fee_charged')
                    @requests_1.each do |hash|
                        user_id = hash["ride1.user_id"]
                        user_ids[user_id] = 0 if !user_ids[user_id]
                        user_ids[user_id] = user_ids[user_id] + 1
                    end
                    @requests_2.each do |hash|
                        user_id = hash["ride2.user_id"]
                        user_ids[user_id] = 0 if !user_ids[user_id]
                        user_ids[user_id] = user_ids[user_id] + 1
                    end
                    start_date = start_date+1.day
                end
                 hash = user_ids.select {|user_id, count| count > 1}
                 hash.each do |user_id, count|
                    csv << [user_id, count]
                end
            end
        end
=begin
        def repeat_usership_3(start_date)
            CSV.open('repeat_usership_match_fee_charged_ride_2.csv', "wb") do |csv|
                csv << ["USER_ID", "#_of_requests"]
                user_ids = {}
                while start_date < Date.today
                    @requests = keen_query_3(start_date.to_time, (start_date+1.day).to_time, 'match_fee_charged')
                    @requests.each do |hash|
                        user_id = hash["user_id"]
                        user_ids[user_id] = 0 if !user_ids[user_id]
                        user_ids[user_id] = user_ids[user_id] + 1
                    end
                    start_date = start_date+1.day
                end
                hash = user_ids.select {|user_id, count| count > 1}
                hash.each do |user_id, count|
                    csv << [user_id, count]
                end
            end
        end
=end
        def keen_query_1(start_time, end_time, collection_name)
          keen.count(collection_name, {
            timeframe: {
              :start => keen_timestamp(start_time),
              :end => keen_timestamp(end_time)
            }, :"group_by" => "user_id",
             filters: [{
              "property_name" => "pickup_hub_id",
              "operator" => "in",
              "property_value" => TaxiLine.all.map{|taxi_line| taxi_line.weeels_id}
            }],
          }, {
            method: :post,
            max_age: 100000
          })
        end
        def keen_query_2(start_time, end_time, collection_name)
          keen.count(collection_name, {
            timeframe: {
              :start => keen_timestamp(start_time),
              :end => keen_timestamp(end_time)
            }, :"group_by" => "ride1.user_id",
             filters: [{
              "property_name" => "pickup_hub_id",
              "operator" => "in",
              "property_value" => TaxiLine.all.map{|taxi_line| taxi_line.weeels_id}
            }]
          }, {
            method: :post,
            max_age: 100000
          })
        end
        def keen_query_3(start_time, end_time, collection_name)
          keen.count(collection_name, {
            timeframe: {
              :start => keen_timestamp(start_time),
              :end => keen_timestamp(end_time)
            }, :"group_by" => "ride2.user_id",
             filters: [{
              "property_name" => "pickup_hub_id",
              "operator" => "in",
              "property_value" => TaxiLine.all.map{|taxi_line| taxi_line.weeels_id}
            }]
          }, {
            method: :post,
            max_age: 100000
          })
        end
=begin
        def keen_query_2(start_time, end_time, collection_name, taxi_line)
            keen.count(collection_name, {
                timeframe: {
                    :start => keen_timestamp(start_time),
                    :end => keen_timestamp(end_time)
                }, filters: [{
                    "property_name" => "user_id",
                    "operator" => "eq",
                    "property_value" =>
                    }]
            }, {
                method: :post,
                max_age: 100000
            })
        end

        @requests.each do |hash|
            csv << hash.values
        end
=end
        def keen_timestamp(t)
          t.iso8601(3)
        end
    end

end
