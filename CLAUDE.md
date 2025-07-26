# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Digital Ocean registry cleaner is a GitHub Actions workflow that automates cleanup of Docker images in DigitalOcean Container Registry. It removes old image tags while preserving recent ones to manage storage costs and keep the registry organized.

## Architecture

GitHub Actions workflow `.github/workflows/registry-cleaner.yml` that:
- Runs on schedule (daily) or manual trigger
- Authenticates using DigitalOcean API token
- Fetches repositories and tags using `doctl` CLI
- Applies age and count-based retention policies
- Supports dry-run mode for safe previewing
- Handles deletion of old tags
- Optionally runs garbage collection to reclaim space

Workflow steps:
1. Install and authenticate doctl
2. Set parameters from inputs or defaults
3. Clean registry (fetch repos, process tags, delete old ones)
4. Check for active garbage collection
5. Run garbage collection if enabled and tags were deleted

## Usage

### Manual Trigger
1. Go to Actions tab in GitHub repository
2. Select "DigitalOcean Registry Cleaner"
3. Click "Run workflow"
4. Configure parameters as needed

### Automatic Schedule
The workflow runs daily at 2 AM UTC by default. Edit the cron expression in the workflow file to customize.

## Workflow Inputs

- `dry_run`: Preview deletions without making changes (default: true for manual, false for scheduled)
- `keep_count`: Number of recent tags to preserve (default: 1)
- `min_age_days`: Minimum age before deletion (default: 7)
- `repositories`: Target specific repositories (comma-separated)
- `run_garbage_collection`: Run GC after cleanup (default: true)

## Prerequisites

- GitHub repository with Actions enabled
- DigitalOcean API token with registry read/delete permissions
- Token added as repository secret `DIGITALOCEAN_ACCESS_TOKEN`

## Important Notes

- The workflow uses `doctl` commands via the official DigitalOcean GitHub Action
- Default settings (keep 1 tag, 7-day minimum age) are designed for continuous deployment
- Manual runs default to dry-run mode for safety
- Scheduled runs execute with dry-run disabled
- Garbage collection runs automatically after tag deletion (can be disabled)
- Registry goes read-only during garbage collection
- The workflow is particularly useful for Kamal deployment cleanup