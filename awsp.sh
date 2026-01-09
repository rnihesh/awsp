#!/usr/bin/env bash
#
# awsp - AWS Profile Switcher
# https://github.com/rnihesh/awsp
#
# A fast and friendly AWS profile switcher for your terminal.
# Supports fuzzy search (fzf), SSO auto-login, and identity verification.
#

awsp() {
  local p out

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
      echo "Available profiles:"
      aws configure list-profiles | sed 's/^/  - /'
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
        aws sts get-caller-identity
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
}

# Show current profile
awsp-current() {
  if [ -n "$AWS_PROFILE" ]; then
    echo -e "\033[32mCurrent: $AWS_PROFILE\033[0m"
  else
    echo "No AWS_PROFILE set (using default)"
  fi
}
