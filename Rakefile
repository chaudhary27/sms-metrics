require './env'
require "google/api_client"
require "google_drive"

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
  desc "getting sms responses with negative_responses filter from keen"
  task :sms_analysis do
    I = Outputs::Metrics.new
    O = I.incoming_sms_responses(Date.today)
  end
end

namespace :google_doc do
  desc "update sms_analysis sheet in google doc"
  task :upload_to_google_drive do
    session = GoogleDrive.saved_session("config.json")
    session.upload_from_file("sms_analysis.csv", "sms_analysis", convert: false)
    #file = session.file_by_title("sms_analysis")
    #file.update_from_file("sms_analysis.csv")
  end
end
