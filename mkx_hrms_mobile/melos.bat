@echo off

if "%1"=="run" (
    if "%2"=="build:apk:employee" (
        echo Building Employee App...
        cd apps\employee_app && flutter build apk --release && cd ..\..
        exit /b 0
    )
    if "%2"=="build:apk:hr" (
        echo Building HR App...
        cd apps\hr_app && flutter build apk --release && cd ..\..
        exit /b 0
    )
    if "%2"=="build:apk:all" (
        if not exist release_apks mkdir release_apks
        echo Building Employee App...
        cd apps\employee_app && flutter build apk --release && copy /y "build\app\outputs\flutter-apk\app-release.apk" "..\..\release_apks\employee_app-release.apk" && cd ..\..
        echo Building HR App...
        cd apps\hr_app && flutter build apk --release && copy /y "build\app\outputs\flutter-apk\app-release.apk" "..\..\release_apks\hr_app-release.apk" && cd ..\..
        echo.
        echo =========================================================
        echo SUCCESS! APKs are saved in the "mkx_hrms_mobile\release_apks" folder!
        echo =========================================================
        exit /b 0
    )
    if "%2"=="run:employee" (
        echo Running Employee App...
        cd apps\employee_app && flutter run && cd ..\..
        exit /b 0
    )
    if "%2"=="run:hr" (
        echo Running HR App...
        cd apps\hr_app && flutter run && cd ..\..
        exit /b 0
    )
)

dart pub global run melos %*
