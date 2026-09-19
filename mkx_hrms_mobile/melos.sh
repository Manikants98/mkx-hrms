#!/bin/bash

if [ "$1" = "run" ]; then
    if [ "$2" = "build:apk:employee" ]; then
        echo "Building Employee App..."
        cd apps/employee_app && flutter build apk --release && cd ../..
        exit 0
    fi
    if [ "$2" = "build:apk:hr" ]; then
        echo "Building HR App..."
        cd apps/hr_app && flutter build apk --release && cd ../..
        exit 0
    fi
    if [ "$2" = "build:apk:all" ]; then
        mkdir -p release_apks
        echo "Building Employee App..."
        cd apps/employee_app && flutter build apk --release && cp "build/app/outputs/flutter-apk/app-release.apk" "../../release_apks/employee_app-release.apk" && cd ../..
        echo "Building HR App..."
        cd apps/hr_app && flutter build apk --release && cp "build/app/outputs/flutter-apk/app-release.apk" "../../release_apks/hr_app-release.apk" && cd ../..
        echo ""
        echo "========================================================="
        echo "SUCCESS! APKs are saved in the mkx_hrms_mobile/release_apks folder!"
        echo "========================================================="
        exit 0
    fi
    if [ "$2" = "run:employee" ]; then
        echo "Running Employee App..."
        cd apps/employee_app && flutter run && cd ../..
        exit 0
    fi
    if [ "$2" = "run:hr" ]; then
        echo "Running HR App..."
        cd apps/hr_app && flutter run && cd ../..
        exit 0
    fi
fi

dart pub global run melos "$@"
