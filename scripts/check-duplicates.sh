#!/bin/bash

# Sonarr Duplication Cleanup Script
echo "=== Sonarr Duplication Analysis ==="
echo "Date: $(date)"
echo ""

cd /mnt/media-storage

echo "🔍 Analyzing file duplication..."
echo ""

# Initialize counters
total_duplicated_size=0
files_to_delete=0

echo "📺 Checking TV Show files..."
echo "Format: [ACTION] Download File → Media File"
echo ""

# Check for files that exist in both downloads and media
find downloads/complete/tv-sonarr -name "*.mp4" -o -name "*.mkv" 2>/dev/null | while read downloadfile; do
    # Extract just the filename without path
    filename=$(basename "$downloadfile")
    
    # Look for this file in the media directory
    mediafile=$(find media/tv -name "*$filename*" -o -name "*$(echo $filename | sed 's/\./ /g' | awk '{print $1}')*.mp4" -o -name "*$(echo $filename | sed 's/\./ /g' | awk '{print $1}')*.mkv" 2>/dev/null | head -1)
    
    if [ -n "$mediafile" ]; then
        # Get file sizes
        download_size=$(stat -f%z "$downloadfile" 2>/dev/null || stat -c%s "$downloadfile" 2>/dev/null || echo "0")
        media_size=$(stat -f%z "$mediafile" 2>/dev/null || stat -c%s "$mediafile" 2>/dev/null || echo "0")
        
        # Convert to human readable
        download_size_h=$(numfmt --to=iec $download_size 2>/dev/null || echo "$download_size bytes")
        
        # Check if they're the same file (hardlink) or different files (copy)
        download_inode=$(ls -i "$downloadfile" | awk '{print $1}')
        media_inode=$(ls -i "$mediafile" | awk '{print $1}')
        
        if [ "$download_inode" = "$media_inode" ]; then
            echo "✅ [HARDLINK] $downloadfile → $mediafile"
        else
            echo "❌ [DUPLICATE] $downloadfile ($download_size_h) → $mediafile"
            echo "   Can safely delete: $downloadfile"
            echo ""
        fi
    else
        echo "⚠️  [ORPHAN] $downloadfile (no matching media file found)"
    fi
done

echo ""
echo "🎬 Checking Movie files..."

# Check movies - improved matching logic
find downloads/complete/radarr -name "*.mp4" -o -name "*.mkv" 2>/dev/null | while read downloadfile; do
    filename=$(basename "$downloadfile")
    
    # Extract movie name and year from filename for better matching
    # Handle formats like "The.Matrix.Reloaded.2003..." -> "Matrix Reloaded (2003)"
    movie_name=$(echo "$filename" | sed 's/\.[0-9][0-9][0-9][0-9]\..*//g' | sed 's/\./ /g')
    year=$(echo "$filename" | grep -o '[0-9][0-9][0-9][0-9]' | head -1)
    
    # Look for this movie in the movies directory with flexible matching
    mediafile=$(find media/movies -name "*$movie_name*" -name "*.mkv" -o -name "*$movie_name*" -name "*.mp4" 2>/dev/null | head -1)
    
    # If not found, try searching by the original filename
    if [ -z "$mediafile" ]; then
        mediafile=$(find media/movies -name "*$filename*" 2>/dev/null | head -1)
    fi
    
    # If still not found, try searching by year and partial name
    if [ -z "$mediafile" ] && [ -n "$year" ]; then
        partial_name=$(echo "$movie_name" | awk '{print $1" "$2}')
        mediafile=$(find media/movies -path "*($year)*" -name "*$partial_name*" 2>/dev/null | head -1)
    fi
    
    if [ -n "$mediafile" ]; then
        download_inode=$(ls -i "$downloadfile" | awk '{print $1}')
        media_inode=$(ls -i "$mediafile" | awk '{print $1}')
        
        download_size=$(stat -f%z "$downloadfile" 2>/dev/null || stat -c%s "$downloadfile" 2>/dev/null || echo "0")
        download_size_h=$(numfmt --to=iec $download_size 2>/dev/null || echo "$download_size bytes")
        
        if [ "$download_inode" = "$media_inode" ]; then
            echo "✅ [HARDLINK] $downloadfile → $mediafile"
        else
            echo "❌ [DUPLICATE] $downloadfile ($download_size_h) → $mediafile"
            echo "   Can safely delete: $downloadfile"
        fi
    else
        echo "⚠️  [ORPHAN] $downloadfile (no matching media file found)"
        echo "   Manual check needed - might be renamed differently"
    fi
done

echo ""
echo "📊 Summary:"
echo "Downloads TV space: $(du -sh downloads/complete/tv-sonarr 2>/dev/null | cut -f1)"
echo "Downloads Movies space: $(du -sh downloads/complete/radarr 2>/dev/null | cut -f1)"
echo "Media TV space: $(du -sh media/tv 2>/dev/null | cut -f1)"
echo "Media Movies space: $(du -sh media/movies 2>/dev/null | cut -f1)"

echo ""
echo "💡 Next Steps:"
echo "1. Fix Sonarr settings (see FIX_SONARR_DUPLICATION.md)"
echo "2. For immediate cleanup, you can manually delete duplicate files marked ❌ above"
echo "3. Run this script again after fixing settings to verify no more duplicates"
