//
//  File 2.swift
//  
//
//  Created by CodeBuilder on 21/10/2023.
//

import Foundation


let PURGE_PYTHON_BINARY = """
rm -rf "$CODESIGNING_FOLDER_PATH/app_packages"
if [ "$EFFECTIVE_PLATFORM_NAME" = "-iphonesimulator" ]; then
	echo "Purging Python modules for iOS Device"
	rm -rf "$CODESIGNING_FOLDER_PATH/app_packages.iphoneos"
	mv "$CODESIGNING_FOLDER_PATH/app_packages.iphonesimulator" "$CODESIGNING_FOLDER_PATH/app_packages"
	find "$CODESIGNING_FOLDER_PATH/python-stdlib" -name "*.*-iphoneos.dylib" -exec rm -f "{}" \\;
else
	echo "Purging Python modules for iOS Simulator"
	rm -rf "$CODESIGNING_FOLDER_PATH/app_packages.iphonesimulator"
	mv "$CODESIGNING_FOLDER_PATH/app_packages.iphoneos" "$CODESIGNING_FOLDER_PATH/app_packages"
	find "$CODESIGNING_FOLDER_PATH" -name "*.*-iphonesimulator.dylib" -exec rm -f "{}" \\;
fi
"""

let SIGN_PYTHON_BINARY = """
set -e

install_dylib () {
	INSTALL_BASE=$1
	FULL_DYLIB=$2

	# The name of the .dylib file
	DYLIB=$(basename "$FULL_DYLIB")
	# The name of the .dylib file, relative to the install base
	RELATIVE_DYLIB=${FULL_DYLIB#$CODESIGNING_FOLDER_PATH/$INSTALL_BASE/}
	# The full dotted name of the binary module, constructed from the file path.
	FULL_MODULE_NAME=$(echo $RELATIVE_DYLIB | cut -d "." -f 1 | tr "/" ".");
	# A bundle identifier; not actually used, but required by Xcode framework packaging
	FRAMEWORK_BUNDLE_ID=$(echo $PRODUCT_BUNDLE_IDENTIFIER.$FULL_MODULE_NAME | tr "_" "-")
	# The name of the framework folder.
	FRAMEWORK_FOLDER="Frameworks/$FULL_MODULE_NAME.framework"

	# If the framework folder doesn't exist, create it.
	if [ ! -d "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER" ]; then
		echo "Creating framework for $RELATIVE_DYLIB"
		mkdir -p "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER"

		cp "$CODESIGNING_FOLDER_PATH/dylib-Info-template.plist" "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER/Info.plist"
		defaults write "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER/Info.plist" CFBundleExecutable -string "$DYLIB"
		defaults write "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER/Info.plist" CFBundleIdentifier -string "$FRAMEWORK_BUNDLE_ID"
	fi
	
	echo "Installing binary for $RELATIVE_DYLIB"
	mv "$FULL_DYLIB" "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER"
}

echo "Install standard library dylibs..."
find "$CODESIGNING_FOLDER_PATH/python-stdlib/lib-dynload" -name "*.dylib" | while read FULL_DYLIB; do
	install_dylib python-stdlib/lib-dynload "$FULL_DYLIB"
done
echo "Install app package dylibs..."
find "$CODESIGNING_FOLDER_PATH/app_packages" -name "*.dylib" | while read FULL_DYLIB; do
	install_dylib app_packages "$FULL_DYLIB"
done
echo "Install app dylibs..."
find "$CODESIGNING_FOLDER_PATH/app" -name "*.dylib" | while read FULL_DYLIB; do
	install_dylib app "$FULL_DYLIB"
done

# Clean up dylib template
rm -f "$CODESIGNING_FOLDER_PATH/dylib-Info-template.plist"

echo "Signing frameworks as $EXPANDED_CODE_SIGN_IDENTITY_NAME ($EXPANDED_CODE_SIGN_IDENTITY)..."
find "$CODESIGNING_FOLDER_PATH/Frameworks" -name "*.framework" -exec /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" ${OTHER_CODE_SIGN_FLAGS:-} -o runtime --timestamp=none --preserve-metadata=identifier,entitlements,flags --generate-entitlement-der "{}" \\;

"""
