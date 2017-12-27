#!/usr/bin/env python

# Get the compatibility UUID from the current version of Xcode and update
# the plugin's Info.plist accordingly:

import os
import plistlib
import subprocess
import sys

dev_path = None
if len(sys.argv) > 1:
    dev_path = "{0}/Contents/Developer/".format(sys.argv[1])
if dev_path is None:
    dev_path = subprocess.check_output(['xcode-select', '-p']).strip()
xcode_info_path = os.path.abspath(os.path.join(dev_path, '../Info'))
compat_uuid = subprocess.check_output(['defaults', 'read', xcode_info_path, 'DVTPlugInCompatibilityUUID']).strip()
info_plist_path = 'XVim2/Info.plist'
info =  plistlib.readPlist(info_plist_path)
uuids = info['DVTPlugInCompatibilityUUIDs']
if compat_uuid not in uuids:
    uuids.append(compat_uuid)
plistlib.writePlist(info, info_plist_path)
