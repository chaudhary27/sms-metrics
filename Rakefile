require './env'

namespace :migrate do
  task :cameras do
    TaxiLine.each do |tl|
      if tl.cameras.count == 0
        camera = Camera.create(
          taxi_line: tl,
          name: "#{tl.name} Primary Camera"
        )

        puts "Created camera #{camera.name}"

        tl.line_snapshots.each do |ls|
          puts "Adding line snapshot #{ls.to_s} to camera #{camera.name}"
          ls.camera = camera
          ls.save
        end
      end
    end
  end
end

namespace :sms do
  desc "getting sms responses with UNSUBSCRIBE filter from keen"
  task :sms_responses do
    I = Outputs::Metrics.new
    O = I.incoming_sms_responses(Date.new(2015,11,1))
  end
end
