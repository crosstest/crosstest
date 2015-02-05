#!/usr/bin/env bash
bundle exec crosstest clear
bundle exec crosstest test ruby
bundle exec crosstest show ruby 'hello world'
