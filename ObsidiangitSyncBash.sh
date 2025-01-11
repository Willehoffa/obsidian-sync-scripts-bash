#!/bin/bash

# Configuration 

VAULT_PATH= #"Path_to_Vault"                 # Replace with your Obsidian vault path  
BRANCH="main"                                # Replace with your desired branch name 
REMOTE="origin"                              # Repalce with your remote name if different 
LOG_FILE="$HOME/.obsidian-sync.log"          # Log File Location 

# Function to log messages with timestamps 
log_message() { 
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "LOG_FILE"
    echo "$1"
}

# Create log file if it doesn't exist 
touch "$LOG_FILE"

# Navigate to vault directory 
cd "$VAULT_PATH" || {
    log_message "Error: Could not change to vault directory at $VAULT_PATH"
    exit "$1" 
}

# Check if directory is a git repository 
if [ ! -d ".git" ]; then { 
    log_message "Error: Could not change to vault directory at $VAULT_PATH"
    exit 1
fi
}

#Pull latest changes 
log_message "Pulling latest changes from remote" 
git pull "$REMOTE" "$BRANCH"|| {
    log_message "Error: Failed to pull latest changes" 
    exit 1  
}


# Pull all changes 
log_message "Adding changes..."
git add . || {
    log_message "Error: Failed to add changes" 
    exit 1 
}

#Create commit with timestamp 
COMMIT_MESSAGE="Vault Backup: $(date '+%Y-%m-%s %H:%M:%S')"
git commit -m "$COMMIT_MESSAGE" || {
    if [ $? -eq 1 ]; then
        log_message "No changes to commit"
        exit 0 
    else
        log_message "Error: Failed to commit changes"
        exit 1 
    fi
} 

# Push Changes 
log_message "Pushing changes to remote..." 
git push "$REMOTE" "$BRANCH" || {
    log_message "Error: Failed to push changes" 
    exit 1 
}

log_message "Sync completed successfully" 

