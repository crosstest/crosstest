#!/usr/bin/env bash
bundle exec crosstest destroy
bundle exec crosstest test ruby
bundle exec crosstest show ruby 'hello world'
