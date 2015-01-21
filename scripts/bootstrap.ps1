bundle install
# Replace sh files w/ ps1 files... they should be platform independent except
# for the file extension.
ls samples/*.sh | %{ move $_ $_.ps1 }
