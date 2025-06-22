#!/bin/bash
# Minecraft Server Setup Script
# This script helps set up common server configurations

echo "Minecraft Server Setup Helper"
echo "============================="
echo
echo "To set time to always day, connect to your server and run these commands:"
echo "1. /time set day"
echo "2. /gamerule doDaylightCycle false"
echo
echo "Other useful commands:"
echo "- /weather clear (clear weather)"
echo "- /gamerule doWeatherCycle false (disable weather changes)"
echo "- /gamerule keepInventory true (keep items on death)"
echo "- /gamerule doMobSpawning false (disable hostile mobs)"
echo
echo "Make sure you're set as an operator in your .env file:"
echo "MINECRAFT_OPS=YourMinecraftUsername"
