#!/usr/bin/env bash
rm -rf docs # Or the test suite will get stuck asking about conflicts
bundle exec omnidoc code2doc java --destination=docs/code2doc/java
bundle exec omnidoc code2doc python --destination=docs/code2doc/python
bundle exec omnidoc code2doc ruby --destination=docs/code2doc/ruby
