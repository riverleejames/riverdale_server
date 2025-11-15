# get_iplayer Setup

BBC iPlayer downloader that runs through Gluetun VPN and downloads content directly into Jellyfin's media directories.

## Setup

1. **Build and start the container:**
   ```bash
   docker-compose up -d --build get_iplayer
   ```

2. **Ensure VPN is set to UK:**
   Make sure your `.env` file has:
   ```bash
   SERVER_COUNTRIES=UK
   ```

## Usage

### Using the Helper Script (Recommended)

The helper script makes it easy to download content organized for Jellyfin:

```bash
# Search for programs
./get_iplayer/download-helper.sh search "Doctor Who"

# Download TV show (goes to /tv directory)
./get_iplayer/download-helper.sh download-tv b0123456 "Doctor Who"

# Download movie/documentary (goes to /movies directory)
./get_iplayer/download-helper.sh download-movie b0987654 "Blue Planet"

# Download by program name (auto-detect)
./get_iplayer/download-helper.sh get "Doctor Who"

# List available TV shows
./get_iplayer/download-helper.sh list-tv

# List available radio programs
./get_iplayer/download-helper.sh list-radio
```

### Direct Docker Commands

You can also run get_iplayer commands directly:

```bash
# Search for programs
docker exec get_iplayer get_iplayer --search "doctor who"

# Download to TV directory (for Jellyfin)
docker exec get_iplayer get_iplayer \
  --pid=b0123456 \
  --output=/tv \
  --file-prefix="<nameshort>/<episodeshort>" \
  --subdir

# Download to Movies directory (for Jellyfin)
docker exec get_iplayer get_iplayer \
  --pid=b0987654 \
  --output=/movies \
  --file-prefix="<name>" \
  --subdir

# List available programs
docker exec get_iplayer get_iplayer --type=tv --refresh

# Download with subtitles
docker exec get_iplayer get_iplayer --pid=b0123456 --subtitles --output=/tv
```

## Directory Structure

- **TV Shows**: Downloads to `${MEDIA_ROOT}/tv` - automatically available in Jellyfin
- **Movies/Documentaries**: Downloads to `${MEDIA_ROOT}/movies` - automatically available in Jellyfin
- **Config**: Stores preferences and cache in `${CONFIG_ROOT}/get_iplayer`

## Jellyfin Integration

Content downloaded by get_iplayer will automatically appear in Jellyfin:

1. TV shows go to the TV library
2. Movies/documentaries go to the Movies library
3. Jellyfin will automatically scan and add metadata

You may need to trigger a library scan in Jellyfin after downloading:
- Dashboard → Libraries → Scan Library

## Useful Options

- `--quality=best` - Download best quality
- `--subtitles` - Download subtitles
- `--file-prefix="<name>"` - Custom file naming
- `--thumbnail` - Download thumbnail
- `--metadata` - Download metadata
- `--type=tv|radio` - Filter by type

## Tips

1. Use `--search` to find the PID (program ID) of content
2. The container runs 24/7, so you can schedule downloads
3. All traffic goes through the UK VPN automatically
4. Check logs: `docker logs get_iplayer`

## Troubleshooting

**If downloads fail:**
```bash
# Check VPN connection
docker exec gluetun sh -c "curl -s https://ipapi.co/json/"

# Update get_iplayer
docker exec get_iplayer get_iplayer --update

# Check container logs
docker logs get_iplayer
```

**Refresh program cache:**
```bash
docker exec get_iplayer get_iplayer --refresh --type=tv
```
