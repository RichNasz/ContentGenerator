# ContentGenerator - Team Distribution Guide

This guide explains how to install and run the unsigned ContentGenerator app for internal team use.

## Quick Start

### Option 1: DMG Installation (Recommended)

1. **Download**: Get the `.dmg` file from your team lead
2. **Mount**: Double-click the DMG file to mount it
3. **Install**: Drag "ContentGenerator" to the Applications folder
4. **Eject**: Eject the DMG from Finder
5. **Launch**: Follow the "First Launch" steps below

### Option 2: ZIP Installation

1. **Download**: Get the `.zip` file from your team lead
2. **Extract**: Double-click to extract the ZIP file
3. **Move**: Move "ContentGenerator.app" to your Applications folder
4. **Launch**: Follow the "First Launch" steps below

## First Launch (Important!)

Since this is an unsigned app, macOS will show a security warning on first launch.

### Method 1: Right-Click Launch

1. Open **Finder** > **Applications**
2. **Right-click** (or Control-click) on "ContentGenerator"
3. Select **"Open"** from the context menu
4. Click **"Open"** in the security dialog
5. The app will launch and remember this choice for future opens

### Method 2: System Settings (macOS Ventura and later)

1. Try to launch the app normally (double-click)
2. When blocked, go to **System Settings** > **Privacy & Security**
3. Scroll down to find the ContentGenerator message
4. Click **"Open Anyway"**
5. Confirm by clicking **"Open"** in the dialog

### Method 3: System Preferences (macOS Monterey and earlier)

1. Try to launch the app normally (double-click)
2. When blocked, go to **System Preferences** > **Security & Privacy**
3. Click the **Privacy** tab
4. Click **"Open Anyway"** next to the ContentGenerator message
5. Confirm by clicking **"Open"** in the dialog

## Verification

After successful installation, you should be able to:

- Launch ContentGenerator from Applications
- Create new projects
- Add specification sections
- Attach reference files
- Configure LLM connections
- Generate content

### Checksum Verification

To verify your download is authentic:

```bash
# Check the SHA-256 checksum
shasum -a 256 ContentGenerator_X.X.X.zip

# Compare with the provided checksum file
```

## Troubleshooting

### "App is damaged and can't be opened"

**Cause**: File corruption during download, or quarantine attribute issues

**Solutions**:
1. Re-download the file and verify checksums
2. Or remove the quarantine attribute:
   ```bash
   xattr -cr /Applications/ContentGenerator.app
   ```
   Then try launching again with right-click > Open

### "ContentGenerator cannot be opened because the developer cannot be verified"

**Cause**: Normal behavior for unsigned apps

**Solution**: Use the "Right-Click Launch" method described above

### App crashes on launch

**Cause**: Compatibility issues or corrupted installation

**Solutions**:
1. Delete the app and reinstall from fresh download
2. Check Console.app for crash logs
3. Ensure macOS version meets requirements

### LLM connections not working

**Cause**: Network issues or invalid configuration

**Solutions**:
1. Check your internet connection
2. Verify API keys are correct in Settings > LLM Connections
3. Test the API endpoint with curl or another tool
4. Ensure firewall allows outgoing HTTPS connections

### Reference files not accessible

**Cause**: File permissions or moved/deleted files

**Solutions**:
1. Use the "Locate" button to re-link missing files
2. Ensure files are in accessible locations (not in protected system folders)
3. Check file permissions are readable

## System Requirements

- **macOS**: 26.3 or later
- **Architecture**: Apple Silicon (M1/M2/M3/M4) or Intel
- **Memory**: 4GB RAM minimum, 8GB recommended
- **Storage**: 500MB free space
- **Network**: Internet connection for LLM services

## Getting Started

### 1. Create Your First Project

1. Launch ContentGenerator
2. Click the **+** button in the sidebar header
3. A new project is created with an auto-generated name
4. Click the name to edit it

### 2. Configure LLM Connection

1. Go to **Settings** in the sidebar
2. Select **LLM Connections**
3. Click **Add Connection** and configure:
   - **Name**: Descriptive name (e.g., "OpenAI GPT-4")
   - **Base URL**: API endpoint (e.g., https://api.openai.com)
   - **API Key**: Your authentication key
   - **Model**: Model identifier (e.g., "gpt-4")

### 3. Add Reference Files

1. Select your project
2. Scroll to the **Reference Files** section
3. Click **Add File** or drag files onto the area
4. Supported formats: .txt, .md, .rtf

### 4. Create Specification Sections

1. In your project, add specification sections
2. Fill in section details:
   - **Name**: Section title
   - **Description**: What this section covers
   - **Content**: The actual specification text
   - **Generation Prompt**: Instructions for AI content generation
   - **Usage Prompt**: How to use this section in generation

### 5. Generate Content

1. Click the generate button for your project
2. Select which sections and reference files to include
3. Choose an LLM connection
4. Wait for generation to complete
5. Review and refine the generated content

## Security Notes

### Why do I see security warnings?

This is an **unsigned build** for internal team use. Apple requires apps distributed outside the App Store to be signed and notarized. The security warning is normal and expected for unsigned apps.

### Is the app safe?

- Built from trusted internal source code
- No malicious code or tracking
- Internal development build
- Not notarized by Apple (hence the warnings)

### What data is stored/shared?

- **Local Storage**: All projects, settings, and generated content stored locally on your Mac
- **Network**: Only API calls to your configured LLM services
- **No Telemetry**: The app does not collect or transmit usage data

## Updates

### How to Update

1. Download the new version
2. Quit the current ContentGenerator app
3. Replace the app in your Applications folder (or drag new version over old)
4. Launch the new version
5. Your projects and settings are preserved in the app's data storage

### Version Information

Check current version: **ContentGenerator** menu > **About ContentGenerator**

## Support

### Before Asking for Help

1. Check this troubleshooting guide
2. Verify your system meets requirements
3. Try restarting the app
4. Check Console.app for error messages

### Getting Help

Contact your development team with:

- macOS version (Apple menu > About This Mac)
- App version (ContentGenerator > About ContentGenerator)
- Error messages (exact text or screenshot)
- Steps that led to the issue
- Relevant log entries from Console.app

## Best Practices

### Project Organization

- Use descriptive project names
- Keep related content in single projects
- Use sections to organize different content areas

### LLM Usage

- Test different models for different content types
- Start with conservative settings and adjust
- Always review AI-generated content before use

### File Management

- Keep reference files organized
- Use consistent naming conventions
- Back up important projects by exporting to JSON

---

*This guide is for internal team use only. Do not distribute outside the organization.*
