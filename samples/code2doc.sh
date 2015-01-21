#!/usr/bin/env bash -e
bundle exec crossdoc code2doc java --destination=docs/code2doc/java
bundle exec crossdoc code2doc python --destination=docs/code2doc/python
bundle exec crossdoc code2doc ruby --destination=docs/code2doc/ruby
