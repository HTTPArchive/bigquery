#!/bin/bash
#
# Work in progress

bq query --project_id httparchive --headless "`cat sql/helpers/pwaCandidates.sql`"
bq query --project_id httparchive --headless "`cat sql/helpers/manifests.sql`"
bq query --project_id httparchive --headless "`cat sql/helpers/serviceWorkers.sql`"
