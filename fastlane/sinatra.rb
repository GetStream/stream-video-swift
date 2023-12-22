require 'sinatra'
require 'fileutils'

post '/push/:udid/:bundle_id' do
  push_data_file = 'push_payload.json'
  File.write(push_data_file, request.body.read)
  puts `xcrun simctl push #{params['udid']} #{params['bundle_id']} #{push_data_file}`
end

post '/connection/:state' do
  ['Ethernet', 'Wi-Fi'].each do |service|
    `networksetup -setnetworkserviceenabled '#{service}' #{params['state']} || true`
  end
end

get '/deeplink' do
  deeplink = "streamvideo://getstream.io/video/demos/?id=#{params['id']}"

  <<-HTML
    <!DOCTYPE html>
    <html>
      <body style="text-align: center;">
        <div style="margin-top: 50%;">
          <button style="font-size: 50px; padding: 20px 40px;" onclick="window.location.href = '#{deeplink}'">Open deeplink</button>
        </div>
      </body>
    </html>
  HTML
end

get '/deeplink/join/:id' do
  deeplink = "streamvideo://getstream.io/video/demos/join/#{params['id']}"

  <<-HTML
    <!DOCTYPE html>
    <html>
      <body style="text-align: center;">
        <div style="margin-top: 50%;">
          <button style="font-size: 50px; padding: 20px 40px;" onclick="window.location.href = '#{deeplink}'">Open deeplink</button>
        </div>
      </body>
    </html>
  HTML
end

post '/record_video/:udid/:test_name' do
  recordings_dir = 'recordings'
  video_base_name = "#{recordings_dir}/#{params['test_name']}"
  recordings = (0..Dir["#{recordings_dir}/*"].length + 1).to_a
  body = JSON.parse(request.body.read)
  FileUtils.mkdir_p(recordings_dir)

  video_file = ''
  if body['delete']
    recordings.reverse_each do |i|
      video_file = "#{video_base_name}_#{i}.mp4"
      break if File.exist?(video_file)
    end
  else
    recordings.each do |i|
      video_file = "#{video_base_name}_#{i}.mp4"
      break unless File.exist?(video_file)
    end
  end

  if body['stop']
    simctl_processes = `pgrep simctl`.strip.split("\n")
    simctl_processes.each { |pid| `kill -s SIGINT #{pid}` }
    File.delete(video_file) if body['delete'] && File.exist?(video_file)
  else
    puts `xcrun simctl io #{params['udid']} recordVideo --codec h264 --force #{video_file} &`
  end
end
