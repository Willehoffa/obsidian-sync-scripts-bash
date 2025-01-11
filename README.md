#Obsidian Sync Scripts Bash

##Installation for Automating the Sync Process in Bash 

To run script Daily @ 11:30pm 
Create a Cron.sh file 
  1. Save script as setup-cron.sh
  2. make it executable
      chmod +x setup-cron.sh
  3. Execute Script 
      ./setup-cron.sh

```
#!/bin/bash

# Get the absolute path of the sync script
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/ObsidiangitSyncBashlocal.sh"

# Ensure the script is executable
chmod +x "$SCRIPT_PATH"

# Create a temporary file for the new cron job
TEMP_CRON=$(mktemp)

# Export current crontab to temporary file
crontab -l > "$TEMP_CRON" 2>/dev/null

# Remove existing sync job if present
sed -i "\:$SCRIPT_PATH:d" "$TEMP_CRON"

# Add the new cron job with correct spacing
echo "30 23 * * * $SCRIPT_PATH >> $HOME/.obsidian-sync.log 2>&1" >> "$TEMP_CRON"

# Install the new cron job
crontab "$TEMP_CRON"
echo "Cron job installed successfully!"

# Clean up
rm "$TEMP_CRON"

# Display current crontab for verification
echo -e "\nCurrent crontab contents:"
crontab -l
```


