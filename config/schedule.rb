# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every 1.day, at: '9am' do
  rake 'sms:sms_analysis'
end

every 1.day, at: '9:30am' do
  rake 'google_doc:upload_to_google_drive'
end

every 7.day, at: '9am' do
  rake 'NPS:nps_avg'
end

every 7.day, at: '9:30' do
  rake 'google_doc:update_in_google_doc'
end
