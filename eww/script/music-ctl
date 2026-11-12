arg=$1

get_music_info() {
  title=$(mpc --format "%title%" current 2>/dev/null)
  file=$(mpc --format "%file%" current)
  artist=$(mpc --format "%artist%" current 2>/dev/null)

  if [[ -z "$file" ]]; then
    echo "No Music"
    exit
  elif [[ -z "$title" ]]; then
    base="${file%.*}"
    artist="${base%% - *}"
    title="${base#* - }"
  fi

  echo "$artist - $title"
}

get_music_status() {
  echo "$(mpc status | awk 'NR==2 {print $1}' | tr -d '[]' || 'No Music')"
}

get_music_cover() {
  MUSIC_DIR="$HOME/Shared/Music"
  COVER_DIR="$HOME/Shared/.cover"
  FALLBACK_COVER="$HOME/Pictures/Icons/pochita.icon"

  current_file=$(mpc -f %file% current)

  if [ -z "$current_file" ]; then
      echo "$FALLBACK_COVER"
      exit
  fi

  full_path="$MUSIC_DIR/$current_file"

  cover_filename=$(ffprobe -v error -select_streams v:0 -show_entries stream_tags=title -of default=noprint_wrappers=1:nokey=1 "$full_path" 2>/dev/null)

  if [ -n "$cover_filename" ]; then
      cover_path="$COVER_DIR/$cover_filename"
      
      if [ -f "$cover_path" ]; then
          echo "$cover_path"
          return
      fi
  else
    echo "$FALLBACK_COVER"
  fi
}

get_music_stream() {
  status=$(mpc status 2>/dev/null)

  awk 'NR==2 {
      if (match($0, /([0-9]+:[0-9]+)\/([0-9]+:[0-9]+) \(([0-9]+)%\)/, arr)) {
          printf "%s|%s|%s\n", arr[1], arr[2], arr[3]
      } else {
          print "0:00|0:00|0"
      }
  }' <<< "$status"
}



if [[ $arg == "status" ]]; then
  get_music_status

  mpc idleloop player | while read -r; do
    get_music_status
  done
elif [[ $arg == "cover" ]]; then
  get_music_cover

  mpc idleloop player | while read -r; do
      get_music_cover
  done
elif [[ $arg == "stream" ]]; then
  get_music_stream
else
    get_music_info
fi

