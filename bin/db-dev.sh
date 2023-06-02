#!/bin/bash

# dev dbconsole

env PGPASSWORD=postgres \
  psql -U postgres -w -h 127.0.0.1 -p 5432 -d nox_os_dev
