bundle install
pushd samples
  # Replace sh files w/ ps1 files... they should be platform independent except
  # for the file extension.
  Dir *.sh | Rename-Item -NewName {  $_.name  -replace '\.sh$','.ps1'  }
  bundle exec crosstest clone
popd
