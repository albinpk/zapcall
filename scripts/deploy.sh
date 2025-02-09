#!/bin/bash

fvm flutter clean
fvm flutter pub get
fvm flutter build web

# copy build to home server
scp -r build/web server:/home/albin/dev/zapcall
