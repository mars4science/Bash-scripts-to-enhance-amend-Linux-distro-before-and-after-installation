#!/bin/bash
# copy configs that set upload speed limit and seeding limits.

cp /home/mint/Documents/Projects/Scripts/settings/transmission/*.json /home/$(id -un)/.config/transmission
sed --in-place 's`/mint/`/'$(id -un)'/`' /home/$(id -un)/.config/transmission/settings.json
