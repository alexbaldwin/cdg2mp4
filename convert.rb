# ruby convert.rb [ PATH TO CDG ] [ YOUTUBE URL]
song_file = ARGV[0]
song_name = File.basename(song_file,File.extname(song_file))

youtube_url = ARGV[1]

# Download youtube video
system "rm youtube.mp4"
system "youtube-dl \"#{youtube_url}\" -o youtube.mp4 -f mp4"
system "ffmpeg -y -i youtube.mp4 -ss 20 -strict -2 -s hd720 -r 30 background-720p.mp4"

# Combine CDG + MP3
system "rm foreground-720p.mp4"
system "ffmpeg -y -i '#{song_name}.cdg' -i '#{song_name}.mp3' -s hd720 -r 30 -acodec 'copy' -vcodec 'libx264' -f 'mp4' foreground-720p.mp4"

# Extract the keyframe
system "rm keyframe.png"
system "ffmpeg -y -i foreground-720p.mp4 -ss 00:01:00 -vframes 1 keyframe.png"

# Detect color
keyframe_inspect = `convert keyframe.png -colors 1 -format "%c" histogram:info:`
colors = keyframe_inspect.scan /#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})/
chroma = colors[0][0]

# Figure out how long the song is
mp3_seconds =  `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 '#{song_name}.mp3'`
mp4_seconds =  `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 background-720p.mp4`

# If background-720p is shorter than mp3, we will need to loop
if mp4_seconds < mp3_seconds
  loops = mp3_seconds.to_i / mp4_seconds.to_i
  system "ffmpeg -y  -i background-720p.mp4 -c copy background-720p.mkv"
  system "ffmpeg -y -stream_loop #{loops.ceil} -i background-720p.mkv -c copy background-720p.mp4"
end

# Combine videos
system "rm greenScreen.mp4"
system "ffmpeg -y -i background-720p.mp4 -i foreground-720p.mp4 -filter_complex '[1:v]colorkey=##{chroma}\:0.3\:0.2[ckout];[0:v][ckout]overlay[out]' -map '[out]' greenScreen.mp4"

# Add music back in (quicktime is fussy without the codec and pix_fmt flags)
system "rm final.mp4"
system "ffmpeg -y -i greenScreen.mp4 -i '#{song_name}.mp3' -t #{seconds.to_i} -vcodec libx264 -pix_fmt yuv420p final.mp4"

puts "All done 🎉"
