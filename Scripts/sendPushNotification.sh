#!/bin/bash

# Check if a payload file is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_payload_file>"
    exit 1
fi

# Get the file path from the argument
PAYLOAD_FILE=$1

# Check if the payload file exists
if [ ! -f "$PAYLOAD_FILE" ]; then
    echo "Error: File $PAYLOAD_FILE not found!"
    exit 1
fi

# Get the bundle identifier of the app (you should replace this with your app's actual bundle identifier)
BUNDLE_IDENTIFIER="io.getstream.iOS.VideoDemoApp"

# Get a list of booted simulators
BOOTED_SIMULATORS=$(xcrun simctl list devices | grep '(Booted)' | awk -F '[()]' '{print $2}')

# Check if there are any booted simulators
if [ -z "$BOOTED_SIMULATORS" ]; then
    echo "No booted simulators found."
    exit 0
fi

# Send the push notification to each booted simulator
for SIMULATOR_ID in $BOOTED_SIMULATORS; do
    echo "Sending push notification to simulator with ID: $SIMULATOR_ID"
    COMMAND="xcrun simctl push $SIMULATOR_ID $BUNDLE_IDENTIFIER $PAYLOAD_FILE"
    echo "Will execute"
    echo "$COMMAND"
    
    ${COMMAND}
    
    if [ $? -eq 0 ]; then
        echo "Push notification sent to $SIMULATOR_ID successfully."
    else
        echo "Failed to send push notification to $SIMULATOR_ID."
    fi
done

echo "Push notification process completed."