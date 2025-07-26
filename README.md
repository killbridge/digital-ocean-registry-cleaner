# DigitalOcean Container Registry Cleaner

A tool to clean up old Docker images from your DigitalOcean Container Registry, keeping only the most recent tags. Available as both a Ruby script and a GitHub Actions workflow.

## Prerequisites

### For Ruby Script
- Ruby installed on your system
- `doctl` CLI tool installed and authenticated with DigitalOcean
- Access to your DigitalOcean Container Registry

### For GitHub Actions
- GitHub repository with Actions enabled  
- DigitalOcean personal access token with registry read/write permissions
- No local dependencies required

## Ruby Script Usage

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

## GitHub Actions Workflow

This repository also includes a GitHub Actions workflow that provides the same functionality without requiring local dependencies.

### Setup

1. **Create DigitalOcean Access Token**:
   - Go to [DigitalOcean API Tokens](https://cloud.digitalocean.com/account/api/tokens/new)
   - Create a new personal access token with these permissions:
     - **registry** → **read** (View container registries)
     - **registry** → **delete** (Delete container registries)
   - Copy the generated token

2. **Add Token to GitHub**: 
   - Go to your GitHub repository settings
   - Navigate to Secrets and variables → Actions
   - Add a new repository secret named `DIGITALOCEAN_ACCESS_TOKEN`
   - Paste the token value from step 1

3. **Enable GitHub Actions**: 
   - Ensure GitHub Actions is enabled for your repository
   - The workflow file is located at `.github/workflows/registry-cleaner.yml`

### Usage

The workflow can be triggered in two ways:

#### Automatic Schedule
The workflow runs automatically every day at 2 AM UTC with default settings:
- Dry run: **false** (will actually delete images)
- Keep count: 1
- Minimum age: 7 days
- Repositories: all

#### Manual Trigger
You can manually run the workflow from the GitHub Actions tab:

1. Go to Actions → DigitalOcean Registry Cleaner
2. Click "Run workflow"
3. Configure parameters:
   - **dry_run**: Set to true to preview changes without deleting
   - **keep_count**: Number of recent tags to keep
   - **min_age_days**: Minimum age before deletion
   - **repositories**: Comma-separated list of specific repositories (leave empty for all)

### Examples

**Manual dry run:**
- dry_run: `true`
- keep_count: `3`
- min_age_days: `30`
- repositories: `myapp/web,myapp/worker`

**Production cleanup:**
- dry_run: `false`
- keep_count: `1`
- min_age_days: `7`
- repositories: (leave empty for all)

### Monitoring

- View workflow runs in the Actions tab of your GitHub repository
- Each run shows detailed logs of what was kept/deleted
- Failed runs will trigger GitHub notifications (if enabled)

### Customizing the Schedule

To change the automatic schedule, edit the cron expression in `.github/workflows/registry-cleaner.yml`:

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
```

Common examples:
- `'0 0 * * 0'` - Weekly on Sunday at midnight
- `'0 0 1 * *'` - Monthly on the 1st
- `'0 */6 * * *'` - Every 6 hours