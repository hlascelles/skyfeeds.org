#! /usr/bin/env bash
set -euo pipefail

cd "${0%/*}"
bundle check || bundle install
bundle exec rspec
