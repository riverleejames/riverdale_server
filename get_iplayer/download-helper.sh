#!/bin/bash
# get_iplayer download helper script
# This script helps download BBC iPlayer content organized for Jellyfin

# Usage examples:
# ./download-helper.sh search "Doctor Who"
# ./download-helper.sh download-tv <PID> "Show Name"
# ./download-helper.sh download-movie <PID> "Movie Name"

COMMAND=$1
shift

case "$COMMAND" in
    search)
        # Search for content
        docker exec get_iplayer get_iplayer --search "$@"
        ;;
    
    download-tv)
        # Download TV show episode to /tv directory
        PID=$1
        SHOW_NAME=$2
        echo "Downloading TV show: $SHOW_NAME (PID: $PID)"
        docker exec get_iplayer get_iplayer \
            --pid="$PID" \
            --output="/tv" \
            --file-prefix="<nameshort>/<episodeshort>" \
            --subdir
        ;;
    
    download-movie)
        # Download movie/documentary to /movies directory
        PID=$1
        MOVIE_NAME=$2
        echo "Downloading movie: $MOVIE_NAME (PID: $PID)"
        docker exec get_iplayer get_iplayer \
            --pid="$PID" \
            --output="/movies" \
            --file-prefix="<name>" \
            --subdir
        ;;
    
    list-tv)
        # List available TV shows
        docker exec get_iplayer get_iplayer --type=tv --listformat="<pid>|<name>|<episode>" --refresh
        ;;
    
    list-radio)
        # List available radio programs
        docker exec get_iplayer get_iplayer --type=radio --listformat="<pid>|<name>|<episode>" --refresh
        ;;
    
    get)
        # Download by program name (auto-detect type)
        PROGRAM=$1
        echo "Searching and downloading: $PROGRAM"
        docker exec get_iplayer get_iplayer \
            --get "$PROGRAM" \
            --output="/tv" \
            --file-prefix="<nameshort>/<episodeshort>" \
            --subdir
        ;;
    
    help|*)
        echo "get_iplayer Helper Script"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  search <query>              Search for programs"
        echo "  download-tv <PID> <name>    Download TV show episode"
        echo "  download-movie <PID> <name> Download movie/documentary"
        echo "  get <program-name>          Download by program name"
        echo "  list-tv                     List available TV shows"
        echo "  list-radio                  List available radio programs"
        echo ""
        echo "Examples:"
        echo "  $0 search 'Doctor Who'"
        echo "  $0 download-tv b0123456 'Doctor Who'"
        echo "  $0 get 'Doctor Who'"
        ;;
esac
