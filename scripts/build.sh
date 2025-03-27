#!/bin/bash

rm -rf docs

cd apps/zapcall/

fvm flutter clean
fvm flutter pub get
fvm flutter build web

cd ../../

cp -r apps/zapcall/build/web/ docs
