@echo off
setlocal enabledelayedexpansion
rem ============================================================
rem  Easy School Fees Planner - fast publish
rem  Put this file in the ROOT of the website repository, next to
rem  CNAME and index.html. Drop new files into the "trial" folder,
rem  then double-click this file (or run:  publish_site.bat "my note").
rem
rem  trial\landing_index.html  ->  index.html        (landing page)
rem  trial\app_index.html      ->  app\index.html    (sign-in page)
rem  trial\logo.svg            ->  logo.svg
rem  trial\SFP_V*_publish.html ->  NOT put on GitHub. Uploaded to the
rem                                Worker if SFP_WORKER_URL and
rem                                SFP_ADMIN_TOKEN are set (see notes).
rem ============================================================
cd /d "%~dp0"

if not exist "trial\" (
  echo There is no "trial" folder next to this file.
  pause
  exit /b 1
)
git --version >nul 2>&1
if errorlevel 1 (
  echo Git is not installed or not on the PATH.
  pause
  exit /b 1
)

set CHANGED=0
if exist "trial\landing_index.html" (
  copy /y "trial\landing_index.html" "index.html" >nul
  echo Landing page copied to index.html
  git add index.html
  set CHANGED=1
)
if exist "trial\app_index.html" (
  if not exist "app\" mkdir app
  copy /y "trial\app_index.html" "app\index.html" >nul
  echo Sign-in page copied to app\index.html
  git add app\index.html
  set CHANGED=1
)
if exist "trial\logo.svg" (
  copy /y "trial\logo.svg" "logo.svg" >nul
  echo Logo copied to logo.svg
  git add logo.svg
  set CHANGED=1
)

if "!CHANGED!"=="0" (
  echo No site files found in the trial folder, so nothing to put on GitHub.
  goto :upload
)

git diff --cached --quiet
if not errorlevel 1 (
  echo The site files are identical to what is already published. Nothing to commit.
  goto :upload
)

set "MSG=%~1"
if "!MSG!"=="" set "MSG=Site update %date% %time:~0,5%"
git commit -m "!MSG!"
if errorlevel 1 (
  echo Commit failed.
  pause
  exit /b 1
)
git pull --rebase
if errorlevel 1 (
  echo Pull failed. Fix the message above, then run this again.
  pause
  exit /b 1
)
git push
if errorlevel 1 (
  echo Push failed. Check you are signed in to GitHub.
  pause
  exit /b 1
)
echo.
echo Published. GitHub Pages usually shows the change within a minute or two.

:upload
rem ---- optional: send the planner itself to the Worker (never to GitHub) ----
set APPFILE=
for %%F in (trial\SFP_V*_publish.html) do set "APPFILE=%%F" & set "APPNAME=%%~nF"
if not defined APPFILE goto :done
if not defined SFP_WORKER_URL (
  echo.
  echo Found %APPFILE% but SFP_WORKER_URL / SFP_ADMIN_TOKEN are not set, so it was not uploaded.
  goto :done
)
if not defined SFP_ADMIN_TOKEN (
  echo.
  echo Found %APPFILE% but SFP_ADMIN_TOKEN is not set, so it was not uploaded.
  goto :done
)
rem SFP_V0_09_publish -> V0.09
set "VER=!APPNAME:~4,5!"
set "VER=!VER:_=.!"
echo.
echo Uploading %APPFILE% to the Worker as !VER! ...
curl -s -X PUT --data-binary "@%APPFILE%" -H "Authorization: Bearer %SFP_ADMIN_TOKEN%" "%SFP_WORKER_URL%/admin/upload-app?version=!VER!"
echo.
echo (A reply starting {"ok":true shows it worked.)

:done
echo.
pause
endlocal
