#!/usr/bin/env bash
bundle exec omnitest clear
bundle exec omnitest test ruby
bundle exec omnitest show ruby 'hello world'
