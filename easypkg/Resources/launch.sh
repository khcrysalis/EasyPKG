#!/bin/bash

PASSWORD=$(
osascript -l JavaScript <<JXA
ObjC.import('stdlib')
const app = Application.currentApplication()
app.includeStandardAdditions = true
const result = app.displayDialog(
  'EasyPKG needs admin permissions. Type your password to allow this.',
  {
    defaultAnswer: '',
    withIcon: 'stop',
    buttons: ['Cancel', 'Ok'],
    defaultButton: 'Ok',
    hiddenAnswer: true
  }
)
if (result.buttonReturned === 'Ok') {
  result.textReturned
} else {
  $.exit(255)
}
JXA
)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="$SCRIPT_DIR/../../../EasyPKG.app"
APP_EXEC="$APP_PATH/Contents/MacOS/EasyPKG"

echo "$PASSWORD" | sudo -S "$APP_EXEC"
