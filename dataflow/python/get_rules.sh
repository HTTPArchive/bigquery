#!/bin/bash

if [ ! -f easyprivacy.txt ]; then
  wget --no-check-certificate https://easylist-downloads.adblockplus.org/easyprivacy.txt -O local/tracker.txt
fi

if [ ! -f easylist_noelemhide.txt ]; then
  wget --no-check-certificate https://easylist-downloads.adblockplus.org/easylist_noelemhide.txt -O local/ad.txt
fi

if [ ! -f fanboy-annoyance.txt ]; then
  wget --no-check-certificate https://easylist-downloads.adblockplus.org/fanboy-annoyance.txt -O local/social.txt
fi

