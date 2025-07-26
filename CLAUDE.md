# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Digital Ocean registry cleaner is a Ruby script that automates cleanup of Docker images in DigitalOcean Container Registry. It removes old image tags while preserving recent ones to manage storage costs and keep the registry organized.

## Architecture

Single Ruby script `registry_cleaner.rb` with the `RegistryCleaner` class that:
- Fetches repositories and tags using `doctl` CLI
- Applies age and count-based retention policies
- Supports dry-run mode for safe previewing
- Handles deletion of old tags

Key methods:
- `run`: Main orchestration
- `fetch_all_repositories`: Lists repositories
- `clean_repository`: Processes individual repos
- `fetch_tags`: Gets tags for a repository
- `delete_tags`: Removes old tags

## Development Commands

```bash
# Run the cleaner
./registry_cleaner.rb [options]

# Lint code (required before commits)
bundle exec standardrb --fix

# Install dependencies
bundle install
```

## Command-line Options

- `-d, --dry-run`: Preview deletions without making changes
- `-k, --keep-count COUNT`: Number of recent tags to preserve (default: 1)
- `-a, --min-age-days DAYS`: Minimum age before deletion (default: 7)
- `-r, --repository REPO`: Target specific repositories
- `-h, --help`: Display help

## Prerequisites

- Ruby installed
- `doctl` CLI installed and authenticated
- Bundle installed for dependency management

## Important Notes

- The script uses `doctl` commands internally, so ensure it's properly authenticated
- Default settings (keep 1 tag, 7-day minimum age) are designed for continuous deployment
- Always run with `--dry-run` first to preview changes
- The tool is particularly useful for Kamal deployment cleanup