#!/usr/bin/env bash
#
# awsp - AWS Profile Switcher
# https://github.com/rnihesh/awsp
#
# A fast and friendly AWS profile switcher for your terminal.
# Supports fuzzy search (fzf), SSO auto-login, and identity verification.
#

AWSP_VERSION="0.0.2"

# Help message
awsp-help() {
  cat <<EOF
awsp - AWS Profile Switcher v${AWSP_VERSION}

Usage:
  awsp                  Interactive profile selection (uses fzf if available)
  awsp <profile>        Switch to a specific profile
  awsp clear|none       Clear current AWS profile
  awsp list             List all available profiles
  awsp status           Show current profile and SSO expiration status
  awsp-current          Show current active profile
  awsp --help|-h        Show this help message
  awsp --version|-v     Show version

Examples:
  awsp                  # Opens interactive selector
  awsp dev              # Switch to 'dev' profile
  awsp prod             # Switch to 'prod' profile
  awsp clear            # Unset AWS_PROFILE
  awsp list             # Show all profiles
  awsp status           # Show current profile and SSO status

More info: https://github.com/rnihesh/awsp
EOF
}

awsp() {
  local p out

  # Handle help and version flags
  case "$1" in
    -h|--help|help)
      awsp-help
      return 0
      ;;
    -v|--version|version)
      echo "awsp v${AWSP_VERSION}"
      return 0
      ;;
    list)
      echo "Available AWS profiles:"
      aws configure list-profiles | sed 's/^/  - /'
      return 0
      ;;
    status)
      awsp-status
      return 0
      ;;
  esac

  # Check if aws cli is installed
  if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI not found. Please install it first."
    return 1
  fi

  # Special case: clear profile
  if [ "$1" = "clear" ] || [ "$1" = "none" ]; then
    unset AWS_PROFILE
    echo "AWS_PROFILE cleared"
    return 0
  fi

  if [ -n "$1" ]; then
    if ! aws configure list-profiles | grep -qx "$1"; then
      echo "Profile not found: $1"
      echo "Run 'awsp list' to see available profiles"
      return 1
    fi
    p="$1"
  else
    # Check if fzf is available, fallback to select
    if command -v fzf &> /dev/null; then
      p=$(aws configure list-profiles | fzf --prompt="AWS Profile > " --height=40%)
    else
      echo "Select AWS profile:"
      select p in $(aws configure list-profiles); do
        [ -n "$p" ] && break
      done
    fi
  fi

  [ -z "$p" ] && return

  export AWS_PROFILE="$p"
  echo -e "\033[32mAWS_PROFILE=$AWS_PROFILE\033[0m"

  out=$(aws sts get-caller-identity 2>&1)
  if echo "$out" | grep -qi "Error when retrieving token from sso"; then
    echo -e "\033[33mSSO token expired for profile '$p'\033[0m"
    printf "Run aws sso login now? [y/N]: "
    read -r ans
    case "$ans" in
      y|Y)
        aws sso login --profile "$p" || return 1
        echo -e "\033[32m✓ SSO login successful\033[0m"
        out=$(aws sts get-caller-identity)
        echo "$out"
        ;;
      *)
        echo "Skipped SSO login"
        return 1
        ;;
    esac
  else
    echo -e "\033[32m✓ Identity verified\033[0m"
    echo "$out"
  fi
  
  # Show SSO expiration if this is an SSO profile
  if echo "$out" | grep -q "AWSReservedSSO"; then
    local current_account=$(echo "$out" | grep -o '"Account": "[0-9]*"' | grep -o '[0-9]*')
    local cli_cache_dir="${HOME}/.aws/cli/cache"
    local expires_at
    
    if [ -d "$cli_cache_dir" ] && [ -n "$current_account" ]; then
      for cache_file in "$cli_cache_dir"/*.json; do
        if [ -f "$cache_file" ]; then
          local cache_account=$(jq -r '.Credentials.AccountId // empty' "$cache_file" 2>/dev/null)
          if [ "$cache_account" = "$current_account" ]; then
            expires_at=$(jq -r '.Credentials.Expiration // empty' "$cache_file" 2>/dev/null)
            if [ -n "$expires_at" ]; then
              # Convert to readable format
              local expiry_time
              expiry_time=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$expires_at" "+%Y-%m-%d %H:%M:%S %Z" 2>/dev/null || \
                            date -j -f "%Y-%m-%dT%H:%M:%S%z" "$expires_at" "+%Y-%m-%d %H:%M:%S %Z" 2>/dev/null || \
                            date -d "$expires_at" "+%Y-%m-%d %H:%M:%S %Z" 2>/dev/null || echo "$expires_at")
              
              # Check if expired
              local now=$(date +%s)
              local exp_seconds
              exp_seconds=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$expires_at" "+%s" 2>/dev/null || \
                            date -j -f "%Y-%m-%dT%H:%M:%S%z" "$expires_at" "+%s" 2>/dev/null || \
                            date -d "$expires_at" "+%s" 2>/dev/null || echo 0)
              
              if [ "$exp_seconds" -gt "$now" ]; then
                local remaining=$((exp_seconds - now))
                local hours=$((remaining / 3600))
                local minutes=$(((remaining % 3600) / 60))
                echo -e "\033[36mSSO expires: $expiry_time (${hours}h ${minutes}m remaining)\033[0m"
              else
                echo -e "\033[31mSSO expired: $expiry_time\033[0m"
              fi
              break
            fi
          fi
        fi
      done
    fi
  fi
}

# Show current profile
awsp-current() {
  if [ -n "$AWS_PROFILE" ]; then
    echo -e "\033[32mCurrent: $AWS_PROFILE\033[0m"
  else
    echo "No AWS_PROFILE set (using default)"
  fi
}

# Show status including SSO expiration
awsp-status() {
  if [ -n "$AWS_PROFILE" ]; then
    echo -e "\033[32mCurrent profile: $AWS_PROFILE\033[0m"
    
    # Check if profile uses SSO
    local sso_start_url sso_session sso_region sso_account_id is_sso_profile
    sso_start_url=$(aws configure get sso_start_url --profile "$AWS_PROFILE" 2>/dev/null)
    sso_session=$(aws configure get sso_session --profile "$AWS_PROFILE" 2>/dev/null)
    sso_region=$(aws configure get sso_region --profile "$AWS_PROFILE" 2>/dev/null)
    sso_account_id=$(aws configure get sso_account_id --profile "$AWS_PROFILE" 2>/dev/null)
    
    if [ -n "$sso_start_url" ] || [ -n "$sso_session" ] || [ -n "$sso_region" ] || [ -n "$sso_account_id" ]; then
      is_sso_profile=true
    else
      # Check if current identity indicates SSO (fallback)
      if aws sts get-caller-identity 2>/dev/null | grep -q "AWSReservedSSO"; then
        is_sso_profile=true
      fi
    fi
    
    if [ "$is_sso_profile" = true ]; then
      echo -e "\033[36mSSO Profile\033[0m"
      
      # Get current account ID to match with cache file
      local current_account
      current_account=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
      
      # First, try to get expiration from CLI cache (for role credentials)
      local cli_cache_dir="${HOME}/.aws/cli/cache"
      local expires_at expiry_time
      local found_expiration=false
      
      if [ -d "$cli_cache_dir" ] && [ -n "$current_account" ]; then
        # Search through cache files to find one matching the current account
        for cache_file in "$cli_cache_dir"/*.json; do
          if [ -f "$cache_file" ]; then
            local cache_account=$(jq -r '.Credentials.AccountId // empty' "$cache_file" 2>/dev/null)
            if [ "$cache_account" = "$current_account" ]; then
              expires_at=$(jq -r '.Credentials.Expiration // empty' "$cache_file" 2>/dev/null)
              if [ -n "$expires_at" ]; then
                found_expiration=true
                break
              fi
            fi
          fi
        done
      fi
      
      # If not found in CLI cache, try SSO cache
      if [ "$found_expiration" = false ]; then
        local sso_url
        if [ -n "$sso_start_url" ]; then
          sso_url="$sso_start_url"
        elif [ -n "$sso_session" ]; then
          sso_url=$(aws configure get sso_start_url --profile "$sso_session" 2>/dev/null)
        fi
        
        if [ -n "$sso_url" ]; then
          local cache_dir="${HOME}/.aws/sso/cache"
          local cache_file
          if [ -d "$cache_dir" ]; then
            cache_file=$(grep -l "$sso_url" "$cache_dir"/*.json 2>/dev/null | head -1)
            if [ -f "$cache_file" ]; then
              expires_at=$(jq -r '.expiresAt // empty' "$cache_file" 2>/dev/null)
              if [ -n "$expires_at" ]; then
                found_expiration=true
              fi
            fi
          fi
        fi
      fi
      
      # Display expiration if found
      if [ "$found_expiration" = true ]; then
        # Convert to readable format
        if command -v date &> /dev/null; then
          expiry_time=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$expires_at" "+%Y-%m-%d %H:%M:%S %Z" 2>/dev/null || \
                        date -j -f "%Y-%m-%dT%H:%M:%S%z" "$expires_at" "+%Y-%m-%d %H:%M:%S %Z" 2>/dev/null || \
                        date -d "$expires_at" "+%Y-%m-%d %H:%M:%S %Z" 2>/dev/null || \
                        echo "$expires_at")
        else
          expiry_time="$expires_at"
        fi
        
        # Check if expired
        local now=$(date +%s)
        local exp_seconds
        exp_seconds=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$expires_at" "+%s" 2>/dev/null || \
                      date -j -f "%Y-%m-%dT%H:%M:%S%z" "$expires_at" "+%s" 2>/dev/null || \
                      date -d "$expires_at" "+%s" 2>/dev/null || echo 0)
        
        if [ "$exp_seconds" -gt "$now" ]; then
          local remaining=$((exp_seconds - now))
          local hours=$((remaining / 3600))
          local minutes=$(((remaining % 3600) / 60))
          echo -e "\033[32mSSO expires: $expiry_time (${hours}h ${minutes}m remaining)\033[0m"
        else
          echo -e "\033[31mSSO expired: $expiry_time\033[0m"
        fi
      else
        echo -e "\033[33mSSO expiration not found in cache\033[0m"
      fi
    else
      echo "Regular AWS profile (not SSO)"
    fi
  else
    echo "No AWS_PROFILE set (using default)"
  fi
}
