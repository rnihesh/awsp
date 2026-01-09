# AWSP - AWS Profile Switcher

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash%20%7C%20Zsh-blue.svg)](https://www.gnu.org/software/bash/)

A fast AWS profile switcher for your terminal. Switch between AWS profiles with ease, featuring fuzzy search, SSO support, and automatic identity verification.

## Features

- **Fuzzy Search** - Use `fzf` for interactive profile selection (with fallback to `select`)
- **SSO Support** - Automatic detection of expired SSO tokens with login prompt
- **Identity Verification** - Confirms your identity after profile switch
- **Clear Profile** - Easily unset your AWS profile when needed
- **Colorful Output** - Visual feedback with colored terminal output
- **Zero Dependencies** - Works with just AWS CLI (fzf optional but recommended)

## Installation

### Quick Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/rnihesh/awsp/main/install.sh | bash
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/rnihesh/awsp/main/install.sh | bash
```

### Manual Installation

1. **Clone the repository:**

```bash
git clone https://github.com/rnihesh/awsp.git ~/.awsp
```

2. **Add to your shell configuration:**

For **Zsh** (`~/.zshrc`):

```bash
[ -f ~/.awsp/awsp.sh ] && . ~/.awsp/awsp.sh
```

For **Bash** (`~/.bashrc` or `~/.bash_profile`):

```bash
[ -f ~/.awsp/awsp.sh ] && . ~/.awsp/awsp.sh
```

3. **Reload your shell:**

```bash
source ~/.zshrc  # or source ~/.bashrc
```

## Usage

### Switch Profile (Interactive)

```bash
awsp
```

This opens an interactive fuzzy finder (if `fzf` is installed) or a numbered selection menu to choose your AWS profile.

### Switch to Specific Profile

```bash
awsp my-profile-name
```

Directly switch to a known profile without the interactive menu.

### Clear Current Profile

```bash
awsp clear
# or
awsp none
```

Unsets the `AWS_PROFILE` environment variable.

### Check Current Profile

```bash
awsp-current
```

Shows which AWS profile is currently active.

## Use Cases

### Multi-Account Management

Perfect for developers managing multiple AWS accounts:

```bash
# Switch to development
$ awsp dev-account
AWS_PROFILE=dev-account
Identity verified
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "111111111111",
    "Arn": "arn:aws:iam::111111111111:user/developer"
}

# Quick switch to production
$ awsp prod-account
AWS_PROFILE=prod-account
Identity verified
```

### SSO Workflow

Seamlessly handles AWS SSO authentication:

```bash
$ awsp sso-profile
AWS_PROFILE=sso-profile
SSO token expired for profile 'sso-profile'
Run aws sso login now? [y/N]: y
# Browser opens for SSO authentication
SSO login successful
```

### Clear Profile

Reset to default credentials:

```bash
$ awsp clear
AWS_PROFILE cleared

# Now using default profile or instance role
$ aws sts get-caller-identity
```

## Prerequisites

| Requirement | Required | Notes                                                                                          |
| ----------- | -------- | ---------------------------------------------------------------------------------------------- |
| AWS CLI v2  | Yes      | [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| fzf         | Optional | For fuzzy search. [Install Guide](https://github.com/junegunn/fzf#installation)                |
| Bash/Zsh    | Yes      | Works with both shells                                                                         |

## Configuration

AWSP uses your existing AWS CLI profiles configured in `~/.aws/config` and `~/.aws/credentials`.

### Example AWS Config (`~/.aws/config`)

```ini
[default]
region = us-east-1

[profile dev]
region = us-west-2
output = json

[profile prod]
region = us-east-1
output = json

[profile sso-profile]
sso_start_url = https://my-company.awsapps.com/start
sso_region = us-east-1
sso_account_id = 123456789012
sso_role_name = AdminRole
region = us-east-1
```

## Commands Reference

| Command          | Description                   |
| ---------------- | ----------------------------- |
| `awsp`           | Interactive profile selection |
| `awsp <profile>` | Switch to specific profile    |
| `awsp clear`     | Clear current profile         |
| `awsp none`      | Alias for `awsp clear`        |
| `awsp-current`   | Show current active profile   |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the need to quickly switch between AWS profiles
- Thanks to [fzf](https://github.com/junegunn/fzf) for the fuzzy finder

---

<p align="center">
  Star this repo if you find it useful!
</p>
