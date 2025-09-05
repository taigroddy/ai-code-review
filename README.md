# 🤖 AI Code Review Tool

A powerful AI-powered code review tool that uses Google Gemini to analyze your Git changes and provide comprehensive code reviews with team convention validation.

## ✨ Features

- 🔍 **Intelligent Code Analysis** - Uses Google Gemini AI for comprehensive code review
- 📋 **Convention Validation** - Supports team coding conventions and highlights violations
- 🎯 **API Endpoint Detection** - Automatically detects and analyzes API changes
- 📊 **Structured Reports** - Generates clean, professional markdown reports
- 🚀 **Easy Setup** - One-line installation with automatic PATH configuration
- 🎨 **Beautiful Output** - Color-coded terminal output for better readability

## 🚀 Quick Installation

Install the tool with a single command (includes full setup):

```bash
sh -c "`curl -fsSL https://raw.githubusercontent.com/taigroddy/ai-code-review/main/install.sh`"
```

The installer will automatically:
- ✅ Check system dependencies
- ✅ Guide you through Gemini CLI installation
- ✅ Set up Google Cloud Project configuration
- ✅ Verify authentication
- ✅ Install the tool and create aliases
- ✅ Configure PATH settings

## 📋 Prerequisites

The installer will guide you through setting up:

1. **Gemini CLI** - Interactive installation guide
2. **Google Cloud Project** - Automatic configuration
3. **Authentication** - Verification during setup

No manual setup required! 🎉

## ⚡ Quick Setup

The installer handles everything automatically! If you need to reconfigure later:

```bash
ai-code-review --setup
```

## 🔧 Usage

### Basic Usage

```bash
# Review changes against main branch
ai-code-review --target main

# Using short aliases (installed automatically)
cr --target main
review --target develop

# Review without saving to file
ai-code-review --target develop --no-save

# Save to custom file
ai-code-review --target main --save-to my-review.md
```

### With Team Conventions

```bash
# Include team conventions in review
ai-code-review --target main --convention team-convention.md

# Add Vietnamese translation to review
ai-code-review --target main --language vi

# Combine multiple options
ai-code-review --target main --convention team-convention.md --language vi
```

### Complete Example

```bash
# Full command
ai-code-review --target main \
  --convention team-convention.md \
  --language vi \
  --save-to review-$(date +%Y%m%d).md

# Using short alias
cr --target main --convention team-convention.md --language vi
```

## 📖 Command Options

| Option | Description | Example |
|--------|-------------|---------|
| `--target BRANCH` | Target branch to compare against | `--target main` |
| `--convention FILE` | Team convention file for validation | `--convention rules.md` |
| `--language LANG` | Add additional language output | `--language vi` |
| `--save-to FILE` | Custom output filename | `--save-to review.md` |
| `--no-save` | Don't save to file (terminal only) | `--no-save` |
| `--setup` | Setup tool dependencies | `--setup` |
| `--help` | Show help message | `--help` |
| `--version` | Show version | `--version` |

## 📝 Team Convention File

Create a `team-convention.md` file to define your team's coding standards:

```markdown
# Team Coding Conventions

## Go Guidelines
- Use camelCase for function names
- Use PascalCase for struct names
- Always handle errors explicitly

## API Design
- REST endpoints should follow RESTful conventions
- Use HTTP status codes correctly
- Always return consistent error response format

## Database
- Use snake_case for table and column names
- Always add indexes for foreign keys

## Testing
- Unit tests required for all new functions
- Aim for >80% code coverage
```

## 🌐 Supported Languages

The tool supports bilingual output in the following languages (in addition to English):

| Code | Language | Example Usage |
|------|----------|---------------|
| `vi` | Vietnamese (Tiếng Việt) | `--language vi` |
| `zh` | Chinese (中文) | `--language zh` |
| `ja` | Japanese (日本語) | `--language ja` |
| `ko` | Korean (한국어) | `--language ko` |
| `fr` | French (Français) | `--language fr` |
| `de` | German (Deutsch) | `--language de` |
| `es` | Spanish (Español) | `--language es` |
| `pt` | Portuguese (Português) | `--language pt` |

When a language is specified, the AI will provide translations below the English content for better accessibility.

## ⚡ Quick Aliases

The installer automatically creates convenient aliases for faster usage:

| Alias | Full Command | Usage |
|-------|--------------|-------|
| `cr` | `ai-code-review` | `cr --target main` |
| `code-review` | `ai-code-review` | `code-review --target develop` |
| `review` | `ai-code-review` | `review --target main --language vi` |

These aliases are automatically added to your shell configuration during installation.

## 📊 Sample Output

```
🔄 1. CHANGES
────────────────────────────────────────────────────────────────
📝 - Commits:
    - abc123: Add user authentication system
    - def456: Implement JWT token validation

📁 - Files:
    - auth/: New authentication handlers and middleware
    - users/: User management service updates
    - shared/: JWT utilities and validation helpers

- Summary:
  - Scope: Medium - Authentication system implementation
  - Complexity: High - Security-critical changes with external dependencies
  - Risk Level: High - Authentication affects all protected endpoints
  - Deployment Impact: Requires environment variable configuration

- Convention Violations:
  - auth/handler.go: Function 'process_token' uses snake_case instead of camelCase
  - users/service.go: Missing error handling for database operation

⚡ 2. IMPACT
────────────────────────────────────────────────────────────────
- API Endpoints:
  - POST /auth/login - User authentication with email/password
  - POST /auth/refresh - Refresh JWT token
  - GET /auth/verify - Verify token validity
  - POST /auth/logout - User logout

### With Language Option (--language vi)

```
🔄 1. THAY ĐỔI / CHANGES
────────────────────────────────────────────────────────────────
📝 - Commits / Các commit:
    - abc123: Add user authentication system
    - abc123: Thêm hệ thống xác thực người dùng
    - def456: Implement JWT token validation  
    - def456: Triển khai xác thực JWT token

📁 - Files / Các tệp:
    - auth/: New authentication handlers and middleware
    - auth/: Bộ xử lý và middleware xác thực mới
    - users/: User management service updates
    - users/: Cập nhật dịch vụ quản lý người dùng

- Database Changes:
  - New tables: user_sessions, auth_tokens
  - Table alterations: users table adds last_login_at column
  - Migrations: 3 new migration files
```

## 🔍 What Gets Analyzed

The tool performs comprehensive analysis including:

- **Code Quality** - Structure, patterns, and best practices
- **API Changes** - New/modified/deleted endpoints
- **Database Impact** - Schema changes, migrations, indexes
- **Performance** - Potential bottlenecks and optimizations
- **Security** - Security implications and recommendations
- **Testing** - Test coverage and quality
- **Documentation** - Documentation completeness
- **Convention Compliance** - Team coding standard violations

## 🛠 Environment Setup

### Required Environment Variables

```bash
export GOOGLE_CLOUD_PROJECT="your-project-id"
```

### Authentication

```bash
# Login to Google Cloud
gcloud auth login

# Verify authentication
ai-code-review --setup
```

## 📁 Output Files

Reviews are automatically saved as markdown files:

- **Default naming**: `code-review-YYYYMMDD-HHMMSS.md`
- **Custom naming**: Use `--save-to filename.md`
- **No file output**: Use `--no-save` for terminal-only output

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you encounter any issues:

1. Check the [troubleshooting guide](#troubleshooting)
2. Run `ai-code-review --setup` to verify configuration
3. Open an issue on GitHub with detailed error information

## 🔧 Troubleshooting

### Common Issues

**"Gemini authentication failed"**
```bash
gcloud auth login
export GOOGLE_CLOUD_PROJECT="your-project-id"
```

**"Not a git repository"**
```bash
# Run in a Git repository with committed changes
cd your-project
git status
```

**"No changes found"**
```bash
# Ensure you have commits that differ from target branch
git log --oneline main..HEAD
```

**"Command not found: ai-code-review"**
```bash
# Restart terminal or source your shell config
source ~/.zshrc  # or ~/.bashrc
```

---

Made with ❤️ for better code reviews
