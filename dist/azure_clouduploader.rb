#! /usr/bin/ruby

require 'json'
require 'open3'

start = Time.now
STDOUT.sync = true

# Args: sas token, file, container
if ARGV.length != 5
  raise 'Wrong number of arguments, please provide: user platform upload_file targetdata filename'
end

container_name = ARGV[0]
image_file = ARGV[1]
sas_token = ARGV[2]
storage_account_name = ARGV[3]
file_name = ARGV[4]

def upload_image(file_name, sas_token, storage_account_name, image_file, container_name)
  STDOUT.write("Start uploading image #{image_file}.\n")

  out, err, status = Open3.capture3(
    "az storage blob upload --container-name #{container_name} "\
     "--account-name #{storage_account_name} -f #{image_file} "\
     "-n #{file_name} --sas-token #{sas_token}"
  )

  if status.success?
    STDOUT.write("Successfully uploaded file.\n")
    json = JSON.parse(out)
  else
    abort(err)
  end
end

upload_image(file_name, sas_token, storage_account_name, image_file, container_name)

diff = Time.now - start
STDOUT.write("Upload took: #{Time.at(diff).utc.strftime("%H:%M:%S")}\n")
