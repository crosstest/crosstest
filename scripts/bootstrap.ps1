bundle install
# Replace sh files w/ ps1 files... they should be platform independent except
# for the file extension.
Dir samples/*.sh | Rename-Item -NewName {  $_.name  -replace '\.sh$','.ps1'  }
