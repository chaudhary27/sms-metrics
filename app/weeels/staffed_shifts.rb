require 'csv'
require 'english'

module Weeels
  class StaffedShifts
    attr_accessor :keen, :presences

    def initialize
      @keen = Weeels::Keen.new.client
    end

    def get_beacon_presences_for(taxi_line)
      CSV.open('bp.csv', 'wb') do |csv|
        csv << ["enter_at", "left_at"]
        @presences = (Weeels::BeaconPresences.for_location(taxi_line.weeels_id))
        #@presences
        @presences.each do |presence|
            #get_data_for_time_peroid(presence)
            #print_time_periods_for_bp(presence)
            if presence.left_at != nil && presence.entered_at != nil
              if presence.left_at != presence.entered_at
                csv << [presence.entered_at,presence.left_at]
              end
            end
        end
      end
    end

      # How to capture time_period?
      # time_diff = ((@left_at - @entered_at) * 24 * 60 * 60).to_i
      # takes time_period --> (presence.entered_at - presence.left_at) as an arguments
      # gets request and matches from keen for that time_period. what would be the start_date and end_date in keen query
      # returns REQ/min and MATCH/min for staffing period obtained from BeaconPresences data
      # returns request avg and match avg bases on beacon data (inspect keen_quer)

    def get_data_for_time_peroid(presence)
      CSV.open('bp.csv', 'wb') do |csv|
        csv << ["Date", "enter_at", "left_at", "avg_req_and_match"]
        request_rates = []
        match_rates = []
        left_at = presence.left_at


        if left_at != nil && presence.entered_at != nil
          if left_at != presence.entered_at
            requests = keen_query(presence.entered_at, left_at, 'ride_request', presence.location["id"])
            matches = keen_query(presence.entered_at, left_at, 'match_fee_charged', presence.location["id"])


            m = Outputs::Shift::TimeWindow.new(presence.entered_at, left_at)
            minutes = m.minutes
            request_rates << requests.to_f/minutes
            match_rates << matches.to_f/minutes


          #  csv << ["#{presence.entered_at.to_date}", "#{presence.entered_at.strftime("%H")}:#{presence.entered_at.strftime("%M")}","#{left_at.strftime("%H")}:#{left_at.strftime("%M")}", "#{h}"]
          end
        end

        if request_rates.count > 0
          req_avg = ((request_rates.inject(&:+) || 0)/request_rates.count.to_f).round(4)
        end

        if match_rates.count > 0
          match_avg = ((match_rates.inject(&:+) || 0)/match_rates.count.to_f).round(4)
        end

        h = {
          request_avg: req_avg,
          match_avg: match_avg
        }
      #h
      end
    end
=begin
    def print_time_periods_for_bp(presence)
      CSV.open('bp.csv', 'wb') do |csv|
        csv << ["Date", "enter_at", "left_at"]
        left_at = presence.left_at
        if left_at != nil && presence.entered_at != nil
          if left_at != presence.entered_at
          csv << ["#{presence.entered_at.to_date}", "#{presence.entered_at.strftime("%H")}:#{presence.entered_at.strftime("%M")}","#{left_at.strftime("%H")}:#{left_at.strftime("%M")}"]
          end
        end
      end
    end
=end
    # takes two enter_at for first beacon presence
    # and left_at for second beacon presence
    # enter_at.to_time - left_at.to_time  # gives time diff in seconds
    def merge_bps
      #(((time_periods[0]['enter_at']).to_time -  (time_periods[1]['left_at']).to_time).abs).round(2) # gives diff in minutes
      csv = CSV.read('bp.csv', :headers => true)
        csv.each do |row|
          if $. % 2 == 0
            @a = row['left_at']
          end
          csv.each do |row|
            if $. % 2 != 0
              @b = row['enter_at']
            end
          end
          puts "#{@a} - #{@b}"
        end
    end

    # check for 20 min time window
    # if bp1 - bp2  === 20 min then merge bp1 and bp2
    def mergable?
      merge_bps <= 20.minutes.to_i
    end

    def keen_query_for_merged_bps_times

    end

    def keen_query(start_time, end_time, collection_name, location)
      keen.count(collection_name, {
        timeframe: {
          :start => keen_timestamp(start_time),
          :end => keen_timestamp(end_time)
        }, filters: [{
          "property_name" => "pickup_hub_id",
          "operator" => "eq",
          "property_value" => location
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
