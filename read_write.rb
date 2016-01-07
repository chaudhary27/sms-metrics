require "google/api_client"
require "google_drive"

# Creates a session. This will prompt the credential via command line for the
# first time and save it to config.json file for later usages.
session = GoogleDrive.saved_session("config.json")

# Gets list of remote files.
#session.files.each do |file|
#  p file.title
#end

# Uploads a local file.
session.upload_from_file("sms_analysis.csv", "sms_analysis", convert: false)

# Downloads to a local file.
#file = session.file_by_title("hello.txt")
#file.download_to_file("/faisalfarooq/Desktop/")

# Updates content of the remote file.
#file = session.file_by_title("hello.txt")
#file.update_from_file("hello.txt")
