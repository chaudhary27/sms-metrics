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
