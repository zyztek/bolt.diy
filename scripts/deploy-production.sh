#!/bin/bash

# Production deployment script for bolt.diy
set -e

echo "🚀 Starting production deployment..."

# Check if required tools are installed
command -v pnpm >/dev/null 2>&1 || { echo "❌ pnpm is required but not installed. Aborting." >&2; exit 1; }
command -v wrangler >/dev/null 2>&1 || { echo "❌ wrangler is required but not installed. Aborting." >&2; exit 1; }

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/ dist/ .wrangler/

# Install dependencies
echo "📦 Installing dependencies..."
pnpm install --frozen-lockfile

# Run security audit
echo "🔒 Running security audit..."
pnpm audit --audit-level=high || {
    echo "⚠️  High severity vulnerabilities found. Please review and fix before deploying."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
}

# Run type checking
echo "🔍 Running type checks..."
pnpm typecheck

# Run linting
echo "✨ Running linter..."
pnpm lint

# Run tests
echo "🧪 Running tests..."
pnpm test

# Build for production
echo "🏗️  Building for production..."
pnpm build:prod

# Verify build output
if [ ! -d "build/client" ]; then
    echo "❌ Build failed - output directory not found"
    exit 1
fi

echo "✅ Build completed successfully"

# Deploy to Cloudflare Pages
echo "🌐 Deploying to Cloudflare Pages..."
wrangler pages deploy build/client --project-name=bolt-diy --compatibility-date=2025-03-28

echo "🎉 Deployment completed successfully!"
echo "📊 Health check: curl -f https://your-domain.pages.dev/api/health"