module Outputs
  class Shift
    attr_accessor :keen, :beacon_presences

    def initialize
      @keen = Weeels::Keen.new.client
    end

    def print_as_schedule_string(shifts, skip_match_rates = false)
      lday = -1
      llane = nil
      output = ""
      ::Shift.sorted(shifts).each do |shift|
        if lday != shift.day_of_week
          output << "\n\n#{shift.pretty_day}\n"
          llane = nil
        end

        if llane != shift.taxi_line_id.to_s
          output << lane_info(shift)
          output << header_string(skip_match_rates)
        end

        if skip_match_rates
          output << "#{shift.pretty_start} - #{shift.pretty_end}\t#{shift.average_line_length.round(2)}\n"
        else
          data = get_data_for_shift(shift)
          msg = "#{shift.pretty_start} - #{shift.pretty_end}\t#{shift.average_line_length.round(2)}"
          msg = "#{msg}\t#{data[:request_avg]}\t#{data[:match_avg]}\n"
          output << msg
        end

        lday = shift.day_of_week
        llane = shift.taxi_line_id.to_s
      end

      output
    end

    def print_day_of_week(shifts, csv)
      return nil if shifts.count == 0
      sorted_dates = shifts.map(&:avg_line_length_by_day).map(&:keys).flatten.uniq.sort
      header_row = ["TaxiLine", "start_time", "end_time", "Avg_Line_length"]
      sorted_dates.each do |date|
        header_row << date
      end
      csv << header_row

      shifts.each do |shift|
        #sorted_dates = shift.avg_line_length_by_day.keys.sorts
        csv_entry_for_this_shift = ["#{shift.taxi_line.name}", "#{shift.pretty_start}", "#{shift.pretty_end}","#{shift.average_line_length.round(2)}"]
        sorted_dates.each do |date|
          csv_entry_for_this_shift << shift.avg_line_length_by_day[date]
        end
      csv << csv_entry_for_this_shift
      end
    end

    def print_avg_line_length_by_day(shifts)
      lday = -1
      llane = nil
      day_shifts = []
      CSV.open("line_length_by_day.csv", "wb") do |csv|
        ::Shift.sorted(shifts).each do |shift|
          if lday != shift.day_of_week
            print_day_of_week(day_shifts, csv)
            day_shifts = []
            llane = nil
          end
          day_shifts << shift
          lday = shift.day_of_week
          llane = shift.taxi_line_id.to_s
        end
        print_day_of_week(day_shifts, csv)
      end
    end

    def lane_info(shift)
      msg = "\n#{shift.taxi_line.name}\n"
      msg = "#{msg}#{shift.generation_options_string}" if shift.generation_options
      msg
    end

    def header_string(skip_match_rates)
      if skip_match_rates
        "START - END\tAVG PPL\tDate\n"
      else
        "START - END\tAVG PPL\tREQ /min\tMATCH /min\n"
      end
    end

    def get_data_for_shift(shift)
      request_rates = []
      match_rates = []

      get_staffing_windows_for(shift).each do |window|
        requests = keen_query(window.start_time, window.end_time, 'ride_request', shift)
        matches = keen_query(window.start_time, window.end_time, 'match_fee_charged', shift)
        puts "got #{requests} requests and #{matches} matches"
        minutes = window.minutes
        request_rates << requests.to_f/minutes
        match_rates << matches.to_f/minutes
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
      puts "returning data for shift #{h}"
      h
    end

    def get_staffing_windows_for(shift)
      windows = []
      get_beacon_presences_for(shift).each do |presence|
        new_window = TimeWindow.new(presence.entered_at, presence.left_at)
        touching = touching_windows(new_window, windows)
        if touching && touching.count > 0
          touching.each { |t| windows.delete(t) }
          windows << TimeWindow.merge(*(touching << new_window))
        else
          windows << new_window
        end
      end
      windows.reject { |w| w.minutes <= 0 }.each { |w| w.confine_to_shift(shift) }
    end

    def touching_windows(window, windows)
      windows.select do |w|
        w.overlaps?(window)
      end
    end

    def get_beacon_presences_for(shift)
      presences = []
      shift.source_time_windows.each do |tw|
        presences = presences.concat(Weeels::BeaconPresences.for_time_window(tw[:start], tw[:end], shift.taxi_line.weeels_id))
      end
      presences
    end

    def keen_query(start_time, end_time, collection_name, shift)
      puts "Getting Keen count of #{collection_name} for shift\n\t#{shift.pretty_day}: #{shift.pretty_start} - #{shift.pretty_end}"
      puts "\twithin window #{start_time}-#{end_time}"
      keen.count(collection_name, {
        timeframe: {
          :start => keen_timestamp(start_time),
          :end => keen_timestamp(end_time)
        }, filters: [{
          "property_name" => "pickup_hub_id",
          "operator" => "eq",
          "property_value" => shift.taxi_line.weeels_id
        }]
      }, {
        method: :post,
        max_age: 100000
      })
    end

    def keen_timestamp(t)
      t.iso8601(3)
    end

    class TimeWindow
      attr_accessor :start_time, :end_time

      def self.merge(*time_windows)
        st = time_windows.map(&:start_time).sort.first
        en = time_windows.map(&:end_time).sort.last
        new(st, en)
      end

      def initialize(start_time, end_time)
        @start_time = start_time
        @end_time = end_time
      end

      def minutes
        (end_time - start_time).to_i.to_f / 60.0
      end

      def expand_to_fit(time_window)
        return unless (time_window.start_time && time_window.end_time)
        if start_time > time_window.start_time
          start_time = time_window.start_time
        end
        if end_time < time_window.end_time
          end_time = time_window.end_time
        end
        true
      end

      def confine_to_shift(shift)
        return unless shift.respond_to?(:times_on)
        times = shift.times_on(Time.new(start_time.year, start_time.month, start_time.day))
        time_window = self.class.new(times[:start], times[:end])
        if start_time < time_window.start_time
          start_time = time_window.start_time
        end
        if end_time > time_window.end_time
          end_time = time_window.end_time
        end
        true
      end

      def overlaps?(time_window)
        if start_time < time_window.start_time && end_time < time_window.start_time
          return false
        end
        if start_time > time_window.end_time && end_time > time_window.end_time
          return false
        end
        true
      end
    end
  end
end
