# Scoop Bucket Template

<!-- [![Tests](https://github.com/lz-lunzi/MyBucket/actions/workflows/ci.yml/badge.svg)](https://github.com/lz-lunzi/MyBucket/actions/workflows/ci.yml) [![Excavator](https://github.com/lz-lunzi/MyBucket/actions/workflows/excavator.yml/badge.svg)](https://github.com/lz-lunzi/MyBucket/actions/workflows/excavator.yml) -->

Template bucket for [Scoop](https://scoop.sh), the Windows command-line installer.

## Automated Version Updates

This bucket supports automatic version updates via GitHub Actions:

- **Excavator**: Runs every 4 hours to automatically check for new versions and create pull requests

All applications in this bucket include `checkver` and `autoupdate` fields to enable automatic updates.

## How do I use this template?

1. Generate your own copy of this repository with the "Use this template"
   button.
2. Allow all GitHub Actions:
   - Navigate to `Settings` - `Actions` - `General` - `Actions permissions`.
   - Select `Allow all actions and reusable workflows`.
   - Then `Save`.
3. Allow writing to the repository from within GitHub Actions:
   - Navigate to `Settings` - `Actions` - `General` - `Workflow permissions`.
   - Select `Read and write permissions`.
   - Then `Save`.
4. Document the bucket in `README.md`.
5. Replace the placeholder repository string in `bin/auto-pr.ps1` (already configured for lz-lunzi/MyBucket).
6. Create new manifests by copying `bucket/app-name.json.template` to
   `bucket/<app-name>.json`.
7. Commit and push changes.
8. If you'd like your bucket to be indexed on `https://scoop.sh`, add the
   topic `scoop-bucket` to your repository.

## How do I install these manifests?

After manifests have been committed and pushed, run the following:

```pwsh
scoop bucket add MyBucket https://github.com/lz-lunzi/MyBucket
scoop install MyBucket/<manifestname>
```

## How do I contribute new manifests?

To make a new manifest contribution, please read the [Contributing
Guide](https://github.com/ScoopInstaller/.github/blob/main/.github/CONTRIBUTING.md)
and [App Manifests](https://github.com/ScoopInstaller/Scoop/wiki/App-Manifests)
wiki page.

### Adding Automatic Version Support

When creating a new manifest, ensure you include `checkver` and `autoupdate` fields:

```json
{
    "version": "1.0.0",
    "description": "App description",
    "homepage": "https://example.com",
    "license": "MIT",
    "url": "https://example.com/app-1.0.0.zip",
    "hash": "sha256_hash_here",
    "checkver": {
        "github": "https://github.com/user/repo"
    },
    "autoupdate": {
        "url": "https://example.com/app-$version.zip"
    }
}
```

**Checkver Options:**
- GitHub releases: `{"github": "https://github.com/user/repo"}`
- Custom URL: `{"url": "https://example.com", "regex": "version ([\\d.]+)"}`
- JSON API: `{"url": "https://api.example.com", "jsonpath": "$.version"}`

For more checkver examples, see the [Scoop Wiki](https://github.com/ScoopInstaller/Scoop/wiki/Checkver).

### Manual Version Update Commands

If you need to manually update versions locally:

```pwsh
# Check for updates
scoop bucket add MyBucket .
scoop checkver *

# Update specific app
scoop checkver app-name

# Update all outdated apps
scoop update *
```

