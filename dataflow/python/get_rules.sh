#!/bin/bash

if [ ! -f easyprivacy.txt ]; then
  wget https://easylist-downloads.adblockplus.org/easyprivacy.txt -O local/tracker.txt
fi

if [ ! -f easylist_noelemhide.txt ]; then
  wget https://easylist-downloads.adblockplus.org/easylist_noelemhide.txt -O local/ads.txt
fi

if [ ! -f fanboy-annoyance.txt ]; then
  wget https://easylist-downloads.adblockplus.org/fanboy-annoyance.txt -O local/social.txt
fi

