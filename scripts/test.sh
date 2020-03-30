#!/bin/bash
set -euo pipefail

echo "---  Prepare :bundler: dependencies"
bundle install

echo "+++ Run :rspec:"
bundle exec rspec