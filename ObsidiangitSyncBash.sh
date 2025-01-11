!/bin/bash

# Configuration
VAULT_PATH=#"Path_To_Vault" # Replace with your Obsidian vault path
BRANCH="main" # Replace with your desired branch name
REMOTE="origin" # Replace with your remote name if different
LOG_FILE="$HOME/.obsidian-sync.log" # Log File Location

# Function to log messages with timestamps
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

# Create log file if it doesn't exist
touch "$LOG_FILE"

# Navigate to vault directory
cd "$VAULT_PATH" || {
    log_message "Error: Could not change to vault directory at $VAULT_PATH"
    exit 1
}

# Check if directory is a git repository
if [ ! -d ".git" ]; then
    log_message "Error: Not a git repository. Please initialize a git first"
    exit 1
fi

# Get current branch name
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Switch to main branch if we're on master
if [ "$CURRENT_BRANCH" = "master" ]; then
    log_message "Switching from master to main branch..."
    # First, ensure main branch exists locally
    if ! git show-ref --verify --quiet refs/heads/main; then
        log_message "Creating local main branch..."
        if ! git branch main; then
            log_message "Error: Failed to create main branch"
            exit 1
        fi
    fi
    # Switch to main branch
    if ! git checkout main; then
        log_message "Error: Failed to switch to main branch"
        exit 1
    fi
    # Update CURRENT_BRANCH
    CURRENT_BRANCH="main"
fi

# Fetch latest changes
log_message "Fetching latest changes from remote..."
if ! git fetch "$REMOTE" "$BRANCH"; then
    log_message "Error: Failed to fetch latest changes"
    exit 1
fi

# Ensure proper tracking
if ! git branch -u "$REMOTE/$BRANCH" "$BRANCH" 2>/dev/null; then
    log_message "Note: Branch tracking already set up"
fi

# Check for local changes
if ! git diff-index --quiet HEAD --; then
    log_message "Stashing local changes..."
    if ! git stash; then
        log_message "Error: Failed to stash local changes"
        exit 1
    fi
    HAS_STASH=1
else
    HAS_STASH=0
fi

# Pull with rebase
log_message "Pulling latest changes with rebase..."
if ! git pull --rebase "$REMOTE" "$BRANCH"; then
    log_message "Error: Failed to pull changes with rebase"
    if [ "$HAS_STASH" -eq 1 ]; then
        git stash pop
    fi
    exit 1
fi

# Restore stashed changes if any
if [ "$HAS_STASH" -eq 1 ]; then
    log_message "Restoring local changes..."
    if ! git stash pop; then
        log_message "Error: Failed to restore local changes"
        exit 1
    fi
fi

# Add all changes
log_message "Adding changes..."
if ! git add -A; then
    log_message "Error: Failed to add changes"
    exit 1
fi

# Create commit only if there are changes
if ! git diff --staged --quiet; then
    # Create commit with timestamp
    COMMIT_MESSAGE="Vault Backup: $(date '+%Y-%m-%d %H:%M:%S')"
    if ! git commit -m "$COMMIT_MESSAGE"; then
        log_message "Error: Failed to commit changes"
        exit 1
    fi
    
    # Push Changes
    log_message "Pushing changes to remote..."
    if ! git push "$REMOTE" "$BRANCH"; then
        log_message "Error: Failed to push changes"
        log_message "Attempting force push with lease for safety..."
        if ! git push --force-with-lease "$REMOTE" "$BRANCH"; then
            log_message "Error: Failed to push changes even with force-with-lease"
            exit 1
        fi
    fi
    log_message "Sync completed successfully with new commits"
else
    log_message "No changes to commit"
fi

exit 0

