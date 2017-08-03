# TODO(rviscomi): Consider forking to HTTPArchive.
config="https://raw.githubusercontent.com/AliasIO/Wappalyzer/master/src/apps.json"

# Download.
wget -nv -N $config
if [ $? -ne 0 ]; then
  echo -e "Failed to load latest Wappalyzer config from $config"
  exit
fi

# Sync.
echo -e "Syncing Wappalyzer config to Google Storage"
gsutil cp -n apps.json gs://httparchive/static/wappalyzer.json

# Clean up.
rm apps.json

echo -e "Done"
