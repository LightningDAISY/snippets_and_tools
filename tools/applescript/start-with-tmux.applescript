#! /usr/bin/env osascript

set apiDir to "~/devel/job/API-PROJECT-NAME/"
set apiCom to "bundle exec rails server -b 0.0.0.0"
set webDir to "~/devel/job/WEB-PROJECT-NAME/"
set webCom to "yarn start"
set appDir to "~/devel/job/APP-PROJECT-NAME/"
set appCom to "yarn run ios --simulator='iPhone 15 Pro 17.2'"

tell application "iTerm"
  tell current window
    tell current session
      delay 2
      write text "tmux new-session -s oneSession -n api"
      delay 2
      write text "tmux new-window -t oneSession -n web"
      delay 2
      write text "tmux new-window -t oneSession -n app"
      delay 2
      write text "tmux send-keys -t oneSession:api 'cd " & apiDir & " && " & apiCom & "' C-m"
      write text "tmux send-keys -t oneSession:web 'cd " & webDir & " && " & webCom & "' C-m"
      write text "tmux send-keys -t oneSession:app 'cd " & appDir & " && " & appCom & "' C-m"
    end tell
  end tell
end tell
