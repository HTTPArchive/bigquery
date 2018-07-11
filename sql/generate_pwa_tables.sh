#!/bin/bash
#
# Work in progress

bq query --headless "`cat sql/helpers/pwaCandidates.sql`"
bq query --headless "`cat sql/helpers/manifests.sql`"
bq query --headless "`cat sql/helpers/serviceWorkers.sql`"
