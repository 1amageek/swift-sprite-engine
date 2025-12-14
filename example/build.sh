#!/bin/bash
set -e

# Build script for WispExample
# Builds WASM package and copies resources to output

echo "Building WispExample for WebAssembly..."
swift package --swift-sdk swift-6.2.3-RELEASE_wasm js

# Copy SPM resources to Package output
RESOURCES_SRC=".build/wasm32-unknown-wasip1/debug/WispExample_WispExample.resources/Resources"
PACKAGE_OUT=".build/plugins/PackageToJS/outputs/Package"

echo "Copying resources to Package output..."
if [ -d "$RESOURCES_SRC" ]; then
    cp -r "$RESOURCES_SRC"/* "$PACKAGE_OUT/"
    echo "  Resources copied from SPM bundle"
else
    echo "  Warning: No resources found at $RESOURCES_SRC"
fi

# Copy index.html if exists
if [ -f "WispExample/index.html" ]; then
    cp "WispExample/index.html" "$PACKAGE_OUT/"
    echo "  index.html copied"
fi

# Update WispExample directory with latest build
echo "Updating WispExample directory..."
cp -r "$PACKAGE_OUT"/* "WispExample/" 2>/dev/null || mkdir -p WispExample && cp -r "$PACKAGE_OUT"/* "WispExample/"

echo ""
echo "Build complete!"
echo ""
echo "To run locally:"
echo "  cd WispExample && python3 -m http.server 8080"
echo "  Open http://localhost:8080 (Chrome/Edge with WebGPU)"
