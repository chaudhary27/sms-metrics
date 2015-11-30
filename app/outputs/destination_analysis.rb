module Outputs
    class DestinationAnalysis
        attr_accessor :keen
        def initialize
            @keen = Weeels::Keen.new.client
        end

        def top_destinations_by_match(start_date)
            CSV.open('top_destinations.csv', "wb") do |csv|
                csv << ["dropoff_zipcode", "frequency_of_rides"]
                dropoff_zipcodes = {}
                while start_date < Date.today
                    @requests_1 = keen_query_1(start_date.to_time, (start_date+1.day).to_time, 'match_fee_charged')
                    @requests_2 = keen_query_1(start_date.to_time, (start_date+1.day).to_time, 'match_fee_charged')
                    @requests_1.each do |hash|
                        dropoff_zipcode = hash["ride1.dropoff_zipcode"]
                        dropoff_zipcodes[dropoff_zipcode] = 0 if !dropoff_zipcodes[dropoff_zipcode]
                        dropoff_zipcodes[dropoff_zipcode] = dropoff_zipcodes[dropoff_zipcode] + hash['result']
                    end
                    @requests_2.each do |hash|
                        dropoff_zipcode = hash["ride2.dropoff_zipcode"]
                        dropoff_zipcodes[dropoff_zipcode] = 0 if !dropoff_zipcodes[dropoff_zipcode]
                        dropoff_zipcodes[dropoff_zipcode] = dropoff_zipcodes[dropoff_zipcode] + hash['result']
                    end
                    start_date = start_date + 1.day
                end
                #hash = dropoff_zipcodes.select { |dropoff_zipcode, count| count}
                sort_count = dropoff_zipcodes.sort_by {|dropoff_zipcode, count| count}.reverse
                sort_count.each do |dropoff_zipcode, count|
                    csv << [dropoff_zipcode, count]
                end
            end
        end

        def keen_query_dest_by_match_ride1(start_time, end_time, collection_name)
          keen.count(collection_name, {
            timeframe: {
              :start => keen_timestamp(start_time),
              :end => keen_timestamp(end_time)
            }, :"group_by" => "ride1.dropoff_zipcode",
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

        def keen_query_dest_by_match_ride2(start_time, end_time, collection_name)
          keen.count(collection_name, {
            timeframe: {
              :start => keen_timestamp(start_time),
              :end => keen_timestamp(end_time)
            }, :"group_by" => "ride2.dropoff_zipcode",
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

        def top_destinations_by_request(start_date)
            CSV.open('top_destinations_by_request.csv', "wb") do |csv|
                csv << ["dropoff_zipcode", "frequency_of_rides"]
                dropoff_zipcodes = {}
                while start_date < Date.today
                    @requests = keen_query(start_date.to_time, (start_date+1.day).to_time, 'ride_request')
                    @requests.each do |hash|
                        dropoff_zipcode = hash["dropoff_zipcode"]
                        dropoff_zipcodes[dropoff_zipcode] = 0 if !dropoff_zipcodes[dropoff_zipcode]
                        dropoff_zipcodes[dropoff_zipcode] = dropoff_zipcodes[dropoff_zipcode] + hash['result']
                    end
                    start_date = start_date + 1.day
                end
                hash = dropoff_zipcodes.select { |dropoff_zipcode, count| count}
                sort_count = hash.sort_by {|dropoff_zipcode, count| count}.reverse
                sort_count.each do |dropoff_zipcode, count|
                    csv << [dropoff_zipcode, count]
                end
            end
        end

        def keen_query_dest_by_request(start_time, end_time, collection_name)
            keen.count(collection_name, {
              timeframe: {
                :start => keen_timestamp(start_time),
                :end => keen_timestamp(end_time)
              }, :"group_by" => "dropoff_zipcode",
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

        def keen_timestamp(t)
          t.iso8601(3)
        end
    end
end
