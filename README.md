# DigitalOcean Container Registry Cleaner

A GitHub Actions workflow to automatically clean up old Docker images from your DigitalOcean Container Registry, keeping only the most recent tags.

## Why This Exists

If you're using DigitalOcean Container Registry for continuous deployments (especially with tools like Kamal), you'll quickly accumulate many old image tags that consume storage space and cost money. This workflow automates the cleanup process by:

- **Reducing costs** - DigitalOcean charges for registry storage, so removing old images saves money
- **Improving performance** - Fewer images mean faster registry operations
- **Maintaining safety** - Keeps recent images based on count and age policies
- **Zero maintenance** - Runs automatically on a schedule you define

Built specifically for teams doing frequent deployments who want to keep their registry clean without manual intervention.

## Quick Start

### 1. Fork or Copy This Workflow

**Option A: Fork this repository**
1. Click the "Fork" button at the top of this page
2. Create a fork in your GitHub account
3. Continue with step 2 below

**Option B: Copy just the workflow**
1. Copy `.github/workflows/registry-cleaner.yml` to your existing repository
2. Continue with step 2 below

### 2. Create Your DigitalOcean Token
1. Go to [DigitalOcean API Tokens](https://cloud.digitalocean.com/account/api/tokens/new)
2. Create a token with these permissions:
   - **registry** → **read** (View container registries)
   - **registry** → **delete** (Delete container registries)
3. Copy the generated token

### 3. Add Token to GitHub Secrets
1. In your GitHub repository, go to Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `DIGITALOCEAN_ACCESS_TOKEN`
4. Value: Paste your token from step 2
5. Click "Add secret"

### 4. Enable and Test
1. Go to the Actions tab in your repository
2. If prompted, enable GitHub Actions
3. Find "DigitalOcean Registry Cleaner" and click it
4. Click "Run workflow" → "Run workflow" (keep defaults for dry run)
5. Check the logs to see what would be deleted

### 5. Configure and Deploy
Once you're happy with the dry run results:
- The workflow will run automatically every day at 2 AM UTC
- Or manually trigger it anytime from the Actions tab
- Customize the schedule or defaults by editing the workflow file

## Prerequisites

- GitHub repository with Actions enabled  
- DigitalOcean personal access token with registry permissions
- No local dependencies required

## How it works

1. Fetches all repositories from your registry (or uses specified ones)
2. For each repository, lists all tags sorted by update time
3. Keeps the most recent tags based on `keep_count`
4. Also keeps any tags younger than `min_age_days`
5. Deletes all other tags
6. Optionally runs garbage collection to reclaim disk space

## Safety features

- Dry-run mode by default shows what would be deleted
- Minimum age protection prevents deletion of recent images
- Tags are sorted by update time, not creation time
- Each deletion is logged
- Checks for active garbage collection before starting a new one

## Note for Kamal users

Since you're using Kamal for deployments, this workflow helps maintain a clean registry while ensuring your latest deployed images are always available. The default settings (keep 1 tag, 7 days minimum age) work well for most Kamal deployments.

## Setup

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

## Usage

The workflow can be triggered in two ways:

### Automatic Schedule
The workflow runs automatically every day at 2 AM UTC with default settings:
- Dry run: **false** (will actually delete images)
- Keep count: 1
- Minimum age: 7 days
- Repositories: all

### Manual Trigger
You can manually run the workflow from the GitHub Actions tab:

1. Go to Actions → DigitalOcean Registry Cleaner
2. Click "Run workflow"
3. Configure parameters:
   - **dry_run**: Set to true to preview changes without deleting
   - **keep_count**: Number of recent tags to keep
   - **min_age_days**: Minimum age before deletion
   - **repositories**: Comma-separated list of specific repositories (leave empty for all)
   - **run_garbage_collection**: Run garbage collection after cleanup (default: true)

## Examples

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

## Monitoring

- View workflow runs in the Actions tab of your GitHub repository
- Each run shows detailed logs of what was kept/deleted
- Failed runs will trigger GitHub notifications (if enabled)

## Customizing the Schedule

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

## Garbage Collection

The workflow includes automatic garbage collection to reclaim disk space after deleting tags:

### How it Works
1. After deleting tags, the workflow checks if garbage collection should run
2. It verifies no other garbage collection is currently active
3. If clear, it starts garbage collection with `--include-untagged-manifests`
4. The process runs asynchronously and may take 15+ minutes

### Important Notes
- **Registry goes read-only** during garbage collection (pulls work, pushes don't)
- Only one garbage collection can run at a time per registry
- Garbage collection only runs if tags were actually deleted (not in dry-run mode)
- You can disable it by setting `run_garbage_collection: false` in manual runs

### Why Use Garbage Collection?
- **Reclaim space**: Deleting tags only removes references; GC actually frees disk space
- **Remove untagged manifests**: Cleans up orphaned image layers
- **Optimize registry**: Improves performance by removing unnecessary data

To check garbage collection status manually:
```bash
doctl registry garbage-collection get-active
doctl registry garbage-collection list
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request for bug fixes or improvements.

## License

This project is open source and available under the [MIT License](LICENSE).