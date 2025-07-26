# DigitalOcean Container Registry Cleaner

A Ruby script to clean up old Docker images from your DigitalOcean Container Registry, keeping only the most recent tags.

## Prerequisites

- Ruby installed on your system
- `doctl` CLI tool installed and authenticated with DigitalOcean
- Access to your DigitalOcean Container Registry

## Usage

```bash
./registry_cleaner.rb [options]
```

### Options

- `-d, --dry-run`: Run in dry-run mode (shows what would be deleted without actually deleting)
- `-k, --keep-count COUNT`: Number of recent tags to keep (default: 1)
- `-a, --min-age-days DAYS`: Minimum age in days before deletion (default: 7)
- `-r, --repository REPO`: Specific repository to clean (can be specified multiple times)
- `-h, --help`: Show help message

### Examples

**Dry run on all repositories (recommended first step):**
```bash
./registry_cleaner.rb --dry-run
```

**Keep the last 3 tags, delete anything older than 30 days:**
```bash
./registry_cleaner.rb --keep-count 3 --min-age-days 30
```

**Clean specific repositories only:**
```bash
./registry_cleaner.rb --repository myapp/web --repository myapp/worker
```

**Production cleanup (keep 1 latest tag, delete tags older than 7 days):**
```bash
./registry_cleaner.rb
```

## How it works

1. Fetches all repositories from your registry (or uses specified ones)
2. For each repository, lists all tags sorted by update time
3. Keeps the most recent tags based on `--keep-count`
4. Also keeps any tags younger than `--min-age-days`
5. Deletes all other tags

## Safety features

- Dry-run mode by default shows what would be deleted
- Minimum age protection prevents deletion of recent images
- Tags are sorted by update time, not creation time
- Each deletion is logged

## Note for Kamal users

Since you're using Kamal for deployments, this script will help maintain a clean registry while ensuring your latest deployed images are always available. The default settings (keep 1 tag, 7 days minimum age) should work well for most Kamal deployments.