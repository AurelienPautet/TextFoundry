#!/bin/bash

# ==============================================================================
# CONFIGURATION - EDIT THIS SECTION
# ==============================================================================

# 1. App Details
APP_FILENAME="TextFoundry.app"                  # The name of your exported app file
APP_NAME="TextFoundry"                          # The clean name for the installer
BUNDLE_ID="com.pautet.app.textfoundry"          # Your App's Bundle Identifier
VERSION="1.0"                                   # Version number

# 2. Signing & Notarization Credentials
# Find this in Keychain Access: "Developer ID Installer: Team Name (ID)"
SIGNING_IDENTITY="Developer ID Installer: Laurent Pautet (R3TJ23PHL6)"

# The profile name you created with 'xcrun notarytool store-credentials'
KEYCHAIN_PROFILE="AC_PASSWORD"

# ==============================================================================
# SCRIPT LOGIC (DO NOT EDIT BELOW UNLESS YOU NEED TO CUSTOMIZE)
# ==============================================================================

set -e # Exit immediately if any command fails

# Define paths
SOURCE_APP="./$APP_FILENAME"
BUILD_DIR="./Build_Output"
PAYLOAD_DIR="./Payload_Staging"  # <--- NEW: Temporary holding folder to fix empty PKG
SCRIPTS_DIR="./Temp_Scripts"
UNSIGNED_PKG="$BUILD_DIR/$APP_NAME-unsigned.pkg"
SIGNED_PKG="$BUILD_DIR/$APP_NAME-Installer.pkg"

echo "----------------------------------------------------------------"
echo "🚀 Starting Distribution Build for $APP_NAME"
echo "----------------------------------------------------------------"

# 1. Setup Directories
echo "📂 Setting up directories..."
rm -rf "$BUILD_DIR" "$PAYLOAD_DIR" "$SCRIPTS_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$PAYLOAD_DIR"
mkdir -p "$SCRIPTS_DIR"

# 2. Check if App exists
if [ ! -d "$SOURCE_APP" ]; then
    echo "❌ Error: Could not find '$APP_FILENAME' in the current folder."
    echo "   Please make sure '$APP_FILENAME' is located at: $PWD"
    exit 1
fi

# 3. PREPARE PAYLOAD (The Critical Fix)
# We copy the app INTO the payload folder so pkgbuild sees: Payload_Staging -> TextFoundry.app
echo "📂 Copying App to Staging Area..."
cp -R "$SOURCE_APP" "$PAYLOAD_DIR/"

# 4. Create the Post-Install Script (Auto-Launch & Permissions Helper)
echo "📜 Generating post-install script (fixes permissions & auto-launches)..."
cat <<EOF > "$SCRIPTS_DIR/postinstall"
#!/bin/bash
# Path where the app is installed
APP_PATH="/Applications/$APP_FILENAME"

# Wait for file operations to finish
sleep 2

# Remove quarantine flag (fixes 'Damaged' or 'Translocation' issues)
xattr -cr "\$APP_PATH"

# Launch the app as the logged-in user (not root)
CURRENT_USER=\$(stat -f%Su /dev/console)
sudo -u "\$CURRENT_USER" open "\$APP_PATH"

exit 0
EOF

# Make the script executable
chmod +x "$SCRIPTS_DIR/postinstall"

# 5. Build the Package
# Note: --root is now pointing to PAYLOAD_DIR, not SOURCE_APP directly
echo "📦 Building the Installer Package..."
pkgbuild --root "$PAYLOAD_DIR" \
         --identifier "$BUNDLE_ID" \
         --version "$VERSION" \
         --install-location "/Applications" \
         --scripts "$SCRIPTS_DIR" \
         "$UNSIGNED_PKG"

# 6. Sign the Package
echo "✍️  Signing the Package..."
productsign --sign "$SIGNING_IDENTITY" \
            "$UNSIGNED_PKG" \
            "$SIGNED_PKG"

# 7. Notarize the Package
echo "☁️  Uploading to Apple for Notarization (This may take 2-5 mins)..."
xcrun notarytool submit "$SIGNED_PKG" \
                --keychain-profile "$KEYCHAIN_PROFILE" \
                --wait

# 8. Staple the Ticket
echo "fyp  Stapling the notarization ticket..."
xcrun stapler staple "$SIGNED_PKG"

# 9. Verification & Cleanup
echo "🧹 Cleaning up temporary files..."
rm "$UNSIGNED_PKG"
rm -rf "$PAYLOAD_DIR"
rm -rf "$SCRIPTS_DIR"

echo "----------------------------------------------------------------"
echo "✅ SUCCESS! Your production-ready installer is here:"
echo "   $SIGNED_PKG"
echo "----------------------------------------------------------------"
echo "Test it by running: spctl -a -v --type install \"$SIGNED_PKG\""
