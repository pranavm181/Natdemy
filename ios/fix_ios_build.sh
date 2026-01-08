#!/bin/bash

# iOS Build Fix Script
# Run this from the project root directory

echo "🧹 Cleaning Flutter..."
flutter clean

echo "📦 Getting Flutter packages..."
flutter pub get

echo "📱 Cleaning iOS build artifacts..."
cd ios

echo "🗑️  Removing Pods..."
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec

echo "🗑️  Removing Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "📦 Updating CocoaPods repo..."
pod repo update

echo "📦 Installing pods..."
pod install

echo "✅ Done! Now open ios/Runner.xcworkspace in Xcode"
echo "⚠️  Make sure to set Swift Language Version to 5.0 in Xcode:"
echo "   Runner target → Build Settings → Swift Language Version → 5.0"

cd ..

