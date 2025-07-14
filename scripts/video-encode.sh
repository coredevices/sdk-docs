# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SOURCE=$1;
DIR=$(dirname "$SOURCE")
FILENAME=$(basename "$SOURCE")
EXT="${FILENAME##*.}"
FILENAME="${FILENAME%.*}"

if [ -z "$1" ]
  then
  echo "\nUsage: $0 <MP4_FILE>\n"
  exit 1;
fi

echo "Creating OGV file..."
ffmpeg -i $SOURCE -loglevel panic -q 5 -pix_fmt yuv420p -acodec libvorbis -vcodec libtheora $DIR/$FILENAME.ogv;
echo "Creating WEBM file..."
ffmpeg -i $SOURCE -loglevel panic -c:v libvpx -c:a libvorbis -pix_fmt yuv420p -quality good -b:v 2M -crf 5 -vf "scale=trunc(in_w/2)*2:trunc(in_h/2)*2" $DIR/$FILENAME.webm;
echo "Creating PNG poster..."
ffmpeg -i $SOURCE -loglevel panic -f image2 -ss 0 -vframes 1 $DIR/$FILENAME.png;
echo "Done!"
