# Contributing to AWSP

First off, thank you for considering contributing to AWSP! 🎉

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title** describing the issue
- **Steps to reproduce** the behavior
- **Expected behavior** vs **actual behavior**
- **Environment details**:
  - OS and version
  - Shell (bash/zsh) and version
  - AWS CLI version (`aws --version`)
  - fzf version if installed (`fzf --version`)

### Suggesting Features

Feature suggestions are welcome! Please:

1. Check if the feature has already been suggested
2. Open an issue with the `enhancement` label
3. Describe:
   - What problem it solves
   - How it should work
   - Any alternatives you've considered

### Pull Requests

1. **Fork** the repository
2. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Test your changes** on both bash and zsh if possible
5. **Commit** with a clear message:
   ```bash
   git commit -m "Add: brief description of changes"
   ```
6. **Push** to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Open a Pull Request**

## Development Setup

```bash
# Clone your fork
git clone https://github.com/rnihesh/awsp.git
cd awsp

# Test locally by sourcing the file
source awsp.sh

# Test the functions
awsp-current
awsp
```

## Code Style

- Use 2 spaces for indentation
- Add comments for complex logic
- Keep functions focused and small
- Test on both bash and zsh
- Use `shellcheck` for linting if available

## Commit Message Guidelines

Use clear, descriptive commit messages:

- `Add:` for new features
- `Fix:` for bug fixes
- `Update:` for changes to existing features
- `Docs:` for documentation changes
- `Refactor:` for code improvements

Example:

```
Add: profile completion support for bash
Fix: SSO token detection for newer AWS CLI versions
Docs: add troubleshooting section to README
```

## Questions?

Feel free to open an issue for any questions!

---

Thank you for contributing! 
