#!/bin/bash

# My Bourbon Collection App Restore Script
# This script will restore the project to the last known working state
# Created: May 22, 2025
# Last working commit: 9ce44611421fec256c6514de072774731903216b

echo "Starting My Bourbon Collection App restore process..."

# Check if we're in the right directory
if [ -d "My Bourbon Collection" ]; then
    echo "Found existing project directory. Backing up..."
    mv "My Bourbon Collection" "My Bourbon Collection_backup_$(date +%Y%m%d_%H%M%S)"
fi

# Clone the repository
echo "Cloning the repository..."
git clone https://github.com/anthonyh0114/my-bourbon-collection.git "My Bourbon Collection"

# Change to the project directory
cd "My Bourbon Collection"

# Checkout the known working branch
echo "Checking out the working branch..."
git checkout revert/photo-editor-changes

# Initialize and update submodules (including the website)
echo "Setting up website submodule..."
git submodule update --init --recursive

# Verify the restore
echo "Verifying the restore..."
if [ -f "My Bourbon Collection/My Bourbon Collection/ViewControllers/EditBourbonViewController.swift" ]; then
    echo "✅ Restore successful! The project has been restored to the last working state."
    echo "You can now open the project in Xcode and continue working."
else
    echo "❌ Restore may have failed. Please check the project structure."
fi

echo "
Next steps:
1. Open 'My Bourbon Collection.xcodeproj' in Xcode
2. Build and run the project
3. If you encounter any issues, check the backup directory created during this process

Note: Your previous project directory has been backed up with a timestamp.
You can find it in the parent directory if you need to recover any files.
" 