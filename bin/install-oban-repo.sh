#!/bin/bash

# This needs to be run locally and in the production docker build.

# check if the OBAN_AUTH_KEY is set
if [ -z "$OBAN_AUTH_KEY" ]; then
  echo "OBAN_AUTH_KEY is not set"
  exit 1
fi

mix hex.repo add oban https://getoban.pro/repo \
  --fetch-public-key SHA256:4/OSKi0NRF91QVVXlGAhb/BIMLnK8NHcx/EWs+aIWPc \
  --auth-key "$OBAN_AUTH_KEY"
