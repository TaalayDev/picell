#!/bin/bash

check_flutter() {
  if ! command -v flutter &> /dev/null
  then
    echo "Error: Flutter could not be found in PATH"
    exit 1
  fi
}

open_folder() {
  folderPath=$1
  # Check if folder exists before trying to open
  if [ -d "$folderPath" ]; then
    open "$folderPath"
    if [ $? -eq 0 ]; then
      echo "Folder opened: $folderPath"
    else
      echo "Failed to open folder: $folderPath"
    fi
  else
    echo "Folder not found: $folderPath"
  fi
}

get_yaml_value() {
    # Helper to extract value from pubspec key (e.g., "version:")
    local key=$1
    local file=$2
    grep -m 1 "^${key}:" "$file" | awk '{print $2}'
}

build() {
  buildType=""
  if [ $# -gt 0 ]; then
    buildType="$1"
  else
    read -p "Enter build type (apk, appbundle, ipa, xcarchive, macos, macos-archive): " buildType
  fi

  # Normalize Build Type
  if [ "$buildType" == "apk" ]; then
    echo "Preparing APK build..."
  elif [ "$buildType" == "appbundle" ] || [ "$buildType" == "aab" ]; then
    echo "Preparing AppBundle build..."
    buildType="appbundle"
  elif [ "$buildType" == "ios" ] || [ "$buildType" == "ipa" ]; then
    echo "Preparing iOS build..."
    buildType="ipa" # 'flutter build ipa' is usually preferred over 'ios' for distribution
  elif [ "$buildType" == "xcarchive" ] || [ "$buildType" == "archive" ]; then
    echo "Preparing Xcode archive (.xcarchive) build..."
    buildType="xcarchive"
  elif [ "$buildType" == "macos" ]; then
    echo "Preparing macOS build..."
    buildType="macos"
  elif [ "$buildType" == "macos-archive" ] || [ "$buildType" == "macos_archive" ]; then
    echo "Preparing macOS Xcode archive (.xcarchive) build..."
    buildType="macos-archive"
  else
    echo "Invalid build type: $buildType"
    exit 1
  fi

  # Check dependencies
  # Note: checking if build dir exists is not a perfect way to check if pub get is needed,
  # but keeping your logic here.
  buildDir="build"
  if [ ! -d "$buildDir" ]; then
    echo "Build directory missing. Running flutter pub get..."
    flutter pub get
    if [ $? -ne 0 ]; then
      echo "Pub get failed"
      exit 1
    fi
  fi

  pubspecYaml="pubspec.yaml"
  if [ ! -f "$pubspecYaml" ]; then
      echo "Error: pubspec.yaml not found!"
      exit 1
  fi

  # --- New Versioning Logic ---
  versionRaw=""
  sourceKey="version" # Default source

  # 1. Determine which key to look for based on platform
  if [[ "$buildType" == "apk" || "$buildType" == "appbundle" ]]; then
      # Try to fetch android_version
      versionRaw=$(get_yaml_value "android_version" "$pubspecYaml")
      if [ -n "$versionRaw" ]; then sourceKey="android_version"; fi
  elif [[ "$buildType" == "ipa" || "$buildType" == "xcarchive" || "$buildType" == "macos" || "$buildType" == "macos-archive" ]]; then
      # Try to fetch ios_version
      versionRaw=$(get_yaml_value "ios_version" "$pubspecYaml")
      if [ -n "$versionRaw" ]; then sourceKey="ios_version"; fi
  fi

  # 2. Fallback to default 'version' if specific key was empty
  if [ -z "$versionRaw" ]; then
      versionRaw=$(get_yaml_value "version" "$pubspecYaml")
      sourceKey="version (default)"
  fi

  if [ -z "$versionRaw" ]; then
      echo "Error: Could not find a version number in $pubspecYaml"
      exit 1
  fi

  # 3. Parse Name and Code
  versionName=$(echo "$versionRaw" | cut -d'+' -f1)
  versionCode=$(echo "$versionRaw" | cut -d'+' -f2)

  # Handle case where version has no '+' (e.g. 1.0.0) -> versionCode becomes same as name
  if [ "$versionName" == "$versionCode" ]; then
      versionCode="1"
  fi

  echo "----------------------------------------"
  echo "Source:       $sourceKey"
  echo "Full Version: $versionRaw"
  echo "Version Name: $versionName"
  echo "Version Code: $versionCode"
  echo "----------------------------------------"

  # Execute Build
  # We run this directly instead of eval/capture so you see the progress bar
  if [ "$buildType" == "xcarchive" ]; then
    # There's no 'flutter build xcarchive' target: build the .app via
    # 'flutter build ios', then let Xcode do the actual archiving.
    flutter build ios --release --no-codesign \
      --dart-define VERSION_NAME="$versionName" \
      --dart-define VERSION_CODE="$versionCode" \
      --build-name="$versionName" \
      --build-number="$versionCode"
    buildStatus=$?

    if [ $buildStatus -eq 0 ]; then
      archivePath="build/ios/archive/Runner.xcarchive"
      mkdir -p "build/ios/archive"
      echo "Archiving with xcodebuild..."
      xcodebuild -workspace ios/Runner.xcworkspace \
        -scheme Runner \
        -configuration Release \
        -archivePath "$archivePath" \
        archive
      buildStatus=$?
    fi
  elif [ "$buildType" == "macos-archive" ]; then
    # Generate the current Flutter Release configuration without doing a
    # duplicate ad-hoc build. xcodebuild below owns the real build/sign/archive.
    flutter build macos --release --config-only \
      --dart-define VERSION_NAME="$versionName" \
      --dart-define VERSION_CODE="$versionCode" \
      --build-name="$versionName" \
      --build-number="$versionCode"
    buildStatus=$?

    if [ $buildStatus -eq 0 ]; then
      archivePath="build/macos/archive/Runner.xcarchive"
      mkdir -p "$(dirname "$archivePath")"
      if [ -d "$archivePath" ]; then
        echo "Removing previous macOS archive (it may contain stale signing metadata)..."
        rm -rf "$archivePath"
      fi

      if ! security find-identity -v -p codesigning | grep -q 'Apple Development'; then
        echo "⚠️  No Apple Development signing identity is currently installed."
        echo "Xcode will try to download/create it using the signed-in account."
        echo "If this fails, open Xcode → Settings → Accounts → Manage Certificates."
      fi

      echo "Archiving macOS app with xcodebuild..."
      xcodebuild -workspace macos/Runner.xcworkspace \
        -scheme Runner \
        -configuration Release \
        -archivePath "$archivePath" \
        -allowProvisioningUpdates \
        DEVELOPMENT_TEAM="R23G38C3KB" \
        CODE_SIGN_STYLE="Automatic" \
        CODE_SIGN_IDENTITY="Apple Development" \
        MARKETING_VERSION="$versionName" \
        CURRENT_PROJECT_VERSION="$versionCode" \
        archive
      buildStatus=$?

      if [ $buildStatus -eq 0 ]; then
        archiveTeam=$(/usr/libexec/PlistBuddy \
          -c "Print :ApplicationProperties:Team" \
          "$archivePath/Info.plist" 2>/dev/null)
        archiveSigningIdentity=$(/usr/libexec/PlistBuddy \
          -c "Print :ApplicationProperties:SigningIdentity" \
          "$archivePath/Info.plist" 2>/dev/null)

        if [ -z "$archiveTeam" ] || [ -z "$archiveSigningIdentity" ]; then
          echo "❌ Archive was created without an Apple Development Team/signing identity."
          echo "Open Xcode → Settings → Accounts, sign in, select team R23G38C3KB,"
          echo "then Manage Certificates → + → Apple Development and run again."
          buildStatus=1
        else
          echo "Archive team: $archiveTeam"
          echo "Signing identity: $archiveSigningIdentity"
        fi
      fi
    fi
  else
    flutter build "$buildType" --release \
      --dart-define VERSION_NAME="$versionName" \
      --dart-define VERSION_CODE="$versionCode" \
      --build-name="$versionName" \
      --build-number="$versionCode"
    buildStatus=$?
  fi

  if [ $buildStatus -eq 0 ]; then
    echo "✅ Build success"

    if [ "$buildType" == "ipa" ]; then
      open "/Applications/Transporter.app"
      open_folder "build/ios/ipa"
    elif [ "$buildType" == "xcarchive" ]; then
      # Double-clicking a .xcarchive opens it straight in Xcode's Organizer
      open "build/ios/archive/Runner.xcarchive"
    elif [ "$buildType" == "macos" ]; then
      open "/Applications/Transporter.app"
      open_folder "build/macos/Build/Products/Release"
    elif [ "$buildType" == "macos-archive" ]; then
      echo "Opening macOS archive in Xcode Organizer for validation/upload..."
      open -a Xcode "build/macos/archive/Runner.xcarchive"
    elif [ "$buildType" == "appbundle" ]; then
      open_folder "build/app/outputs/bundle/release"
      open "https://play.google.com/console"
    else
      # APK
      open_folder "build/app/outputs/flutter-apk"
    fi
  else
    echo "❌ Build failed"
    exit 1
  fi
}

start() {
    echo "Select device to start:"
    flutter devices
    
    # Capture devices list to process selection
    devices=$(flutter devices)
    deviceCount=$(echo "$devices" | grep -c '•')

    if [ $deviceCount -eq 0 ]; then
        echo "No device found"
        exit 1
    elif [ $deviceCount -eq 1 ]; then
        # Auto-select the only device
        deviceName=$(echo "$devices" | grep '•' | awk -F '•' '{print $2}' | awk '{print $1}' | head -n 1)
        # Note: awk extraction above depends heavily on flutter output format. 
        # Usually checking the ID (second column) is safer, but keeping close to your logic.
        echo "Starting on detected device..."
        flutter run
    else
        read -p "Enter device ID or name (copy from above): " deviceId
        flutter run -d "$deviceId"
    fi
}

makeModel() {
  if [ $# -eq 0 ]; then
    echo "Please specify model name"
    exit 1
  fi

  modelName="$1"
  echo "Making model $modelName"

  modelDir="lib/data/models"
  modelFile="$modelDir/$modelName.dart"

  if [ ! -d "$modelDir" ]; then
    mkdir -p "$modelDir"
  fi

  if [ -f "$modelFile" ]; then
    echo "Model $modelName already exists"
    exit 1
  fi

  modelTemplate="lib/templates/model.dart"
  if [ ! -f "$modelTemplate" ]; then
      echo "Error: Template not found at $modelTemplate"
      exit 1
  fi

  cp "$modelTemplate" "$modelFile"

  if [ $? -eq 0 ]; then
    echo "Model $modelName created at $modelFile"
  else
    echo "Failed to create model"
    exit 1
  fi
}

# --- Main Execution ---

if [ $# -eq 0 ]; then
  echo "Usage: $0 {build|start|make-model} [args...]"
  echo "  build types: apk, appbundle, ipa, xcarchive, macos, macos-archive"
  exit 1
fi

check_flutter

command="$1"

if [ "$command" == "build" ]; then
  build "${@:2}"
elif [ "$command" == "start" ]; then
  start "${@:2}"
elif [ "$command" == "make-model" ]; then
  makeModel "${@:2}"
else
  echo "Invalid command: $command"
  echo "Available commands: build, start, make-model"
  exit 1
fi
