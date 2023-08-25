system('powershellNew-Item -ItemType directory -Path $HOME\bin')
system('Copy-Item "~src\aws-cli-mfa-login.py" 
       -Destination "$HOME\bin\aws-cli-mfa-login"')
system('Copy-Item "~src\common.py" -Destination "$HOME\bin\common"')