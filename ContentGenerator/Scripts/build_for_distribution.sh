#!/bin/bash

# ContentGenerator Distribution Build Script
# This script builds and prepares the app for unsigned distribution (internal use)

set -e  # Exit on any error

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
APP_NAME="ContentGenerator"
SCHEME_NAME="ContentGenerator"
BUILD_DIR="$PROJECT_DIR/build"
DIST_DIR="$PROJECT_DIR/dist"
ARCHIVE_DIR="$BUILD_DIR/Archives"
EXPORT_DIR="$BUILD_DIR/Export"
DMG_DIR="$DIST_DIR/DMG"
ZIP_DIR="$DIST_DIR/ZIP"
CHECKSUM_DIR="$DIST_DIR/Checksums"
EXPORT_OPTIONS="$SCRIPT_DIR/ExportOptions.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ContentGenerator Distribution Build${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Configuration: Unsigned build for internal/team use${NC}"
echo -e "${BLUE}Project: $PROJECT_DIR${NC}"
echo ""

# Pre-flight checks
echo -e "${YELLOW}Running pre-flight checks...${NC}"

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode command line tools not found${NC}"
    echo -e "${RED}Please install Xcode and command line tools${NC}"
    exit 1
fi

# Check for project file
if [ ! -f "$PROJECT_DIR/$APP_NAME.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}Error: $APP_NAME.xcodeproj not found${NC}"
    echo -e "${RED}Expected at: $PROJECT_DIR/$APP_NAME.xcodeproj${NC}"
    exit 1
fi

# Check for export options plist
if [ ! -f "$EXPORT_OPTIONS" ]; then
    echo -e "${RED}Error: ExportOptions.plist not found${NC}"
    echo -e "${RED}Expected at: $EXPORT_OPTIONS${NC}"
    exit 1
fi

echo -e "${GREEN}Pre-flight checks passed${NC}"
echo ""

# Get app version from build settings
echo -e "${YELLOW}Getting app version...${NC}"
VERSION=$(xcodebuild -showBuildSettings \
    -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$SCHEME_NAME" 2>/dev/null \
    | grep "MARKETING_VERSION" | head -1 | sed 's/.*= //')

if [ -z "$VERSION" ]; then
    VERSION="1.0"
    echo -e "${YELLOW}Could not determine version, using default: $VERSION${NC}"
else
    echo -e "${BLUE}App Version: $VERSION${NC}"
fi

BUILD_NUMBER=$(xcodebuild -showBuildSettings \
    -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$SCHEME_NAME" 2>/dev/null \
    | grep "CURRENT_PROJECT_VERSION" | head -1 | sed 's/.*= //')

if [ -n "$BUILD_NUMBER" ]; then
    echo -e "${BLUE}Build Number: $BUILD_NUMBER${NC}"
fi
echo ""

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"
mkdir -p "$ARCHIVE_DIR"
mkdir -p "$EXPORT_DIR"
mkdir -p "$DMG_DIR"
mkdir -p "$ZIP_DIR"
mkdir -p "$CHECKSUM_DIR"
echo -e "${GREEN}Build directories created${NC}"
echo ""

# Build the archive
ARCHIVE_PATH="$ARCHIVE_DIR/${APP_NAME}_${VERSION}.xcarchive"
echo -e "${YELLOW}Building archive...${NC}"
echo -e "${BLUE}This may take a few minutes...${NC}"

xcodebuild archive \
    -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -archivePath "$ARCHIVE_PATH" \
    -configuration Release \
    -destination "generic/platform=macOS" \
    | grep -E '^(Build|Archive|Compile|Link|Sign|error:|warning:)' || true

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo -e "${RED}Error: Archive creation failed${NC}"
    exit 1
fi
echo -e "${GREEN}Archive created successfully${NC}"
echo ""

# Export the app (unsigned)
echo -e "${YELLOW}Exporting unsigned app...${NC}"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    | grep -E '^(Export|error:|warning:)' || true

# Find the exported app
APP_FILE=$(find "$EXPORT_DIR" -name "*.app" -maxdepth 1 -type d | head -1)
if [ -z "$APP_FILE" ]; then
    echo -e "${RED}Error: No .app file found in export directory${NC}"
    exit 1
fi
APP_FILENAME=$(basename "$APP_FILE")
echo -e "${GREEN}App exported: $APP_FILENAME${NC}"
echo ""

# Create ZIP archive
ZIP_NAME="${APP_NAME}_${VERSION}.zip"
echo -e "${YELLOW}Creating ZIP archive...${NC}"
cd "$EXPORT_DIR"
zip -r -q "$ZIP_DIR/$ZIP_NAME" "$APP_FILENAME"
cd "$PROJECT_DIR"
echo -e "${GREEN}Created: $ZIP_NAME${NC}"
echo ""

# Create DMG
DMG_NAME="${APP_NAME}_${VERSION}.dmg"
TEMP_DMG="$BUILD_DIR/temp.dmg"
FINAL_DMG="$DMG_DIR/$DMG_NAME"
MOUNT_POINT=""

echo -e "${YELLOW}Creating DMG...${NC}"

# Function to cleanup on error
cleanup_dmg() {
    if [ -n "$MOUNT_POINT" ]; then
        hdiutil detach "$MOUNT_POINT" 2>/dev/null || true
    fi
    rm -f "$TEMP_DMG" 2>/dev/null || true
}

# Set trap to cleanup on error
trap cleanup_dmg ERR

# Create temporary DMG (200MB should be plenty for most apps)
if hdiutil create -size 200m -fs HFS+ -volname "$APP_NAME v$VERSION" "$TEMP_DMG" > /dev/null 2>&1; then
    # Mount the temporary DMG
    MOUNT_POINT=$(hdiutil attach "$TEMP_DMG" -readwrite -noverify -noautoopen 2>/dev/null \
        | grep -E '^/dev/' | awk '{for(i=3;i<=NF;i++) printf "%s%s", $i, (i==NF?"":" ")}')

    if [ -n "$MOUNT_POINT" ]; then
        # Copy the app to the DMG
        cp -R "$APP_FILE" "$MOUNT_POINT/"

        # Create Applications symlink for drag-to-install
        ln -s /Applications "$MOUNT_POINT/Applications" 2>/dev/null || true

        # Add installation readme
        cat > "$MOUNT_POINT/README.txt" << 'READMEEOF'
ContentGenerator - Installation Instructions

1. Drag "ContentGenerator.app" to the Applications folder
2. Open Finder and go to Applications
3. Right-click "ContentGenerator" and select "Open"
4. Click "Open" in the security dialog
5. The app is now ready to use!

Note: This is an unsigned build for internal/team use.
You will see a security warning on first launch.
This is normal for apps distributed outside the App Store.

For support, contact your development team.
READMEEOF

        # Unmount the DMG
        if hdiutil detach "$MOUNT_POINT" > /dev/null 2>&1; then
            MOUNT_POINT=""

            # Convert to compressed read-only DMG
            if hdiutil convert "$TEMP_DMG" -format UDZO -o "$FINAL_DMG" > /dev/null 2>&1; then
                rm -f "$TEMP_DMG"
                echo -e "${GREEN}Created: $DMG_NAME${NC}"
                trap - ERR
            else
                echo -e "${YELLOW}Warning: DMG compression failed, ZIP file is available${NC}"
                cleanup_dmg
            fi
        else
            echo -e "${YELLOW}Warning: DMG unmount failed, ZIP file is available${NC}"
            cleanup_dmg
        fi
    else
        echo -e "${YELLOW}Warning: Could not mount DMG, ZIP file is available${NC}"
        cleanup_dmg
    fi
else
    echo -e "${YELLOW}Warning: DMG creation failed, ZIP file is available${NC}"
fi
echo ""

# Generate checksums
CHECKSUM_FILE="$CHECKSUM_DIR/${APP_NAME}_${VERSION}_checksums.txt"
echo -e "${YELLOW}Generating checksums...${NC}"
{
    echo "# $APP_NAME v$VERSION - Distribution Checksums"
    echo "# Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    if [ -f "$ZIP_DIR/$ZIP_NAME" ]; then
        echo "## ZIP File"
        echo "File: $ZIP_NAME"
        shasum -a 256 "$ZIP_DIR/$ZIP_NAME" | awk '{print "SHA-256: " $1}'
        echo ""
    fi

    if [ -f "$DMG_DIR/$DMG_NAME" ]; then
        echo "## DMG File"
        echo "File: $DMG_NAME"
        shasum -a 256 "$DMG_DIR/$DMG_NAME" | awk '{print "SHA-256: " $1}'
        echo ""
    fi

    echo "## Verification"
    echo "To verify a downloaded file, run:"
    echo "  shasum -a 256 <filename>"
    echo "and compare with the checksums above."
} > "$CHECKSUM_FILE"
echo -e "${GREEN}Created checksums file${NC}"
echo ""

# Print summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Distribution Files:${NC}"
if [ -f "$ZIP_DIR/$ZIP_NAME" ]; then
    SIZE=$(du -h "$ZIP_DIR/$ZIP_NAME" | cut -f1)
    echo -e "  ZIP: $ZIP_DIR/$ZIP_NAME ($SIZE)"
fi
if [ -f "$DMG_DIR/$DMG_NAME" ]; then
    SIZE=$(du -h "$DMG_DIR/$DMG_NAME" | cut -f1)
    echo -e "  DMG: $DMG_DIR/$DMG_NAME ($SIZE)"
fi
echo -e "  Checksums: $CHECKSUM_FILE"
echo ""
echo -e "${BLUE}Archive:${NC}"
echo -e "  $ARCHIVE_PATH"
echo ""
echo -e "${YELLOW}Distribution Instructions:${NC}"
echo "1. Share the DMG or ZIP file with team members"
echo "2. Include the checksum for verification"
echo "3. Refer users to TEAM_DISTRIBUTION.md for installation help"
echo ""
echo -e "${GREEN}Ready for distribution!${NC}"
