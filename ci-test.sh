#!/bin/sh

#
# Test runner for the CI server
#

: ${bamboo_capability_system_builder_command_xctool:=/usr/local/bin/xctool}

trap "on_exit" EXIT

# Kill chrome when exiting the script
function on_exit()
{
  if test -f chrome.pid; then
    kill $(cat chrome.pid)
    rm -f chrome.pid
  fi
}

set -ex

# Kill lingering instances of Google Chrome
killall -9 "Google Chrome" || true # ignore errors
while test $(ps aux | grep ^bamboo | grep -i [c]hrome | wc -l) -ne 0; do
  sleep 1
done

# Launch Google Chrome
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    --use-fake-ui-for-media-stream \
    --use-fake-device-for-media-stream \
    --allow-file-access-from-files \
    ./RespokeSDKTests/WebTestBot/index.html &
echo $! > chrome.pid

# Run the test
${bamboo_capability_system_builder_command_xctool} \
    -sdk iphonesimulator \
    -scheme SDKTestUI \
    reporter junit:build/junit-report.xml \
    test
