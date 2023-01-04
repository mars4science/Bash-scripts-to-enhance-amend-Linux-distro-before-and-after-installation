#!/bin/bash

# change default to preview (was edit after install, intent to continue to use xed to edit as ReText deleted BOM)
&>/dev/null retext --version
if [ $? -eq 0 ]; then
    echo -e "[General]\ndefaultPreviewState=normal-preview" > "/home/$(id -un)/.config/ReText project/ReText.conf"
fi

