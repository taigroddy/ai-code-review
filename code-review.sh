#!/bin/bash

# AI Code Review Tool using Gemini
# Usage: ai-code-review --target <branch>

VERSION="1.0.0"
SCRIPT_NAME="ai-code-review"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print colored output
print_error() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header() {
    echo -e "${PURPLE}🔍 $1${NC}"
}

show_help() {
    cat << EOF
${PURPLE}AI Code Review Tool v${VERSION}${NC}

${CYAN}USAGE:${NC}
    $SCRIPT_NAME --target <branch> [OPTIONS]

${CYAN}OPTIONS:${NC}
    -h, --help              Show this help message
    -v, --version           Show version
    --target BRANCH         Target branch to compare against (e.g., main, develop)
    --setup                 Setup authentication and dependencies
    --save-to FILE          Save review results to specified file (default: code-review-YYYYMMDD-HHMMSS.md)
    --no-save              Don't save review results to file (output only to console)
    --convention FILE       Include team convention file as context for review
    --language LANG         Add additional language output (vi, zh, ja, ko, fr, de, es, pt)

${CYAN}EXAMPLES:${NC}
    $SCRIPT_NAME --target main                    # Review and save to default file
    $SCRIPT_NAME --target develop --no-save       # Review without saving to file
    $SCRIPT_NAME --target main --save-to review.md # Save to custom file
    $SCRIPT_NAME --target main --convention team-convention.md # Include team conventions
    $SCRIPT_NAME --target main --language vi         # Add Vietnamese translation
    $SCRIPT_NAME --setup                          # Setup tool dependencies

${CYAN}REQUIREMENTS:${NC}
    1. Git repository with commits
    2. Gemini CLI installed
    3. GOOGLE_CLOUD_PROJECT environment variable set
    4. Authenticated with Google Cloud

${CYAN}OUTPUT FILES:${NC}
    Review results are saved to markdown files in the project root directory.
    Default filename format: code-review-YYYYMMDD-HHMMSS.md

EOF
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not a git repository. Please run this command in a git repository."
        return 1
    fi
    return 0
}

# Check if required dependencies are installed
check_dependencies() {
    local missing_deps=()
    
    # Check for git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    # Check for gemini command
    if ! command -v gemini &> /dev/null; then
        missing_deps+=("gemini")
        print_info "Install Gemini CLI from: https://github.com/google/generative-ai-cli"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# Check authentication and project setup
check_auth_setup() {
    # Check if GOOGLE_CLOUD_PROJECT is set
    if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
        print_error "GOOGLE_CLOUD_PROJECT environment variable is not set"
        echo ""
        print_info "Set it by running: export GOOGLE_CLOUD_PROJECT=\"your-project-id\""
        print_info "Example: export GOOGLE_CLOUD_PROJECT=\"vn-codeassist\""
        return 1
    fi
    
    # Test gemini command
    print_info "Testing Gemini authentication..."
    if ! gemini -p "test" &> /dev/null; then
        print_error "Gemini authentication failed"
        echo ""
        print_info "Login with: gcloud auth login"
        return 1
    fi
    
    print_success "Authentication verified"
    return 0
}

# Check git status to ensure changes are committed
check_git_status() {
    print_info "Checking git status..."
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        print_error "You have uncommitted changes. Please commit your changes before running code review."
        echo ""
        print_info "Uncommitted files:"
        git status --porcelain
        echo ""
        print_info "Commit your changes with:"
        print_info "  git add ."
        print_info "  git commit -m \"Your commit message\""
        return 1
    fi
    
    print_success "All changes are committed"
    return 0
}

# Check if target branch exists
check_target_branch() {
    local target_branch="$1"
    
    # Check if branch exists locally
    if git show-ref --verify --quiet refs/heads/"$target_branch"; then
        return 0
    fi
    
    # Check if branch exists remotely
    if git show-ref --verify --quiet refs/remotes/origin/"$target_branch"; then
        return 0
    fi
    
    print_error "Branch '$target_branch' not found locally or remotely"
    print_info "Available branches:"
    git branch -a
    return 1
}

# Get list of changed files
get_changed_files() {
    local target_branch="$1"
    local current_branch=$(git branch --show-current)
    
    print_info "Comparing $current_branch with $target_branch..." >&2
    
    # Get the merge base to compare from the common ancestor
    local merge_base=$(git merge-base HEAD "$target_branch" 2>/dev/null)
    if [ -z "$merge_base" ]; then
        merge_base="$target_branch"
    fi
    
    # Get list of changed files
    git diff --name-only "$merge_base"...HEAD
}

# Get git diff for changed files
get_git_diff() {
    local target_branch="$1"
    local current_branch=$(git branch --show-current)
    
    # Get the merge base
    local merge_base=$(git merge-base HEAD "$target_branch" 2>/dev/null)
    if [ -z "$merge_base" ]; then
        merge_base="$target_branch"
    fi
    
    # Get diff stats first to check size
    local diff_stats=$(git diff --stat "$merge_base"...HEAD 2>/dev/null)
    local files_changed=$(echo "$diff_stats" | tail -1 | grep -o '[0-9]\+ files\? changed' | grep -o '[0-9]\+' || echo "0")
    local lines_changed=$(echo "$diff_stats" | tail -1 | grep -o '[0-9]\+ insertions\|[0-9]\+ deletions' | head -1 | grep -o '[0-9]\+' || echo "0")
    
    # If too many files or lines changed, provide summary instead of full diff
    if [ "$files_changed" -gt 50 ] || [ "$lines_changed" -gt 2000 ]; then
        print_warning "Large changeset detected ($files_changed files, $lines_changed+ lines)"
        print_info "Providing summary instead of full diff to avoid command line limits"
        
        echo "=== DIFF SUMMARY ==="
        echo "$diff_stats"
        echo ""
        echo "=== SAMPLE DIFF (First 10 files) ==="
        local sample_files=$(git diff --name-only "$merge_base"...HEAD | head -10)
        for file in $sample_files; do
            echo "--- Changes in $file ---"
            git diff "$merge_base"...HEAD -- "$file" | head -50
            echo ""
        done
        echo "=== END SAMPLE DIFF ==="
    else
        # Get full diff for smaller changesets
        git diff "$merge_base"...HEAD
    fi
}

# Extract API endpoint changes from modules folder
extract_api_changes() {
    local target_branch="$1"
    local current_branch=$(git branch --show-current)
    
    # Get the merge base
    local merge_base=$(git merge-base HEAD "$target_branch" 2>/dev/null)
    if [ -z "$merge_base" ]; then
        merge_base="$target_branch"
    fi
    
    # Get diff for gw/modules folder specifically
    local modules_diff=$(git diff "$merge_base"...HEAD -- "*/modules/*.go" 2>/dev/null)
    
    if [ -z "$modules_diff" ]; then
        echo "No API changes detected in modules folder"
        return
    fi
    
    echo "=== API ENDPOINT CHANGES ==="
    echo ""
    
    # Extract route definitions from the diff
    local route_changes=$(echo "$modules_diff" | grep -E "^\+.*\.(Get|Post|Put|Delete|Patch)\(" | sed 's/^+//')
    
    if [ -n "$route_changes" ]; then
        echo "New/Modified Route Definitions:"
        echo "$route_changes" | while IFS= read -r line; do
            # Clean up the line and extract method and path
            local clean_line=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            echo "  • $clean_line"
        done
        echo ""
    fi
    
    # Extract handler function definitions
    local handler_changes=$(echo "$modules_diff" | grep -E "^\+.*func.*\(.*\*fiber\.Ctx\)" | sed 's/^+//')
    
    if [ -n "$handler_changes" ]; then
        echo "New/Modified Handler Functions:"
        echo "$handler_changes" | while IFS= read -r line; do
            local clean_line=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            echo "  • $clean_line"
        done
        echo ""
    fi
    
    # Show relevant diff sections for routes.go files
    local routes_files=$(echo "$modules_diff" | grep -E "^\+\+\+ b/.*routes\.go" | sed 's/^+++ b\///')
    
    if [ -n "$routes_files" ]; then
        echo "Routes Files Changed:"
        echo "$routes_files" | while IFS= read -r file; do
            echo "  📁 $file"
            # Show the actual diff content for this routes file
            git diff "$merge_base"...HEAD -- "$file" | grep -A 10 -B 2 -E "^\+.*\.(Get|Post|Put|Delete|Patch)\(" | sed 's/^/    /'
            echo ""
        done
    fi
    
    echo "=== END API CHANGES ==="
}

# Create review prompt for Gemini
create_review_prompt() {
    local changed_files="$1"
    local git_diff="$2"
    local target_branch="$3"
    local convention_content="$4"
    local api_changes="$5"
    local language="$6"
    local current_branch=$(git branch --show-current)
    
    # Get commit list between branches
    local merge_base=$(git merge-base HEAD "$target_branch" 2>/dev/null)
    if [ -z "$merge_base" ]; then
        merge_base="$target_branch"
    fi
    
    local commit_list=$(git log --oneline "$merge_base"...HEAD 2>/dev/null || echo "No commits found")
    
    # Language mapping for prompts
    local language_instruction=""
    case "$language" in
        "vi")
            language_instruction="After each English section, provide Vietnamese translation in the same format. Use format: [ENGLISH CONTENT] followed by [VIETNAMESE CONTENT]."
            ;;
        "zh")
            language_instruction="After each English section, provide Chinese translation in the same format. Use format: [ENGLISH CONTENT] followed by [CHINESE CONTENT]."
            ;;
        "ja")
            language_instruction="After each English section, provide Japanese translation in the same format. Use format: [ENGLISH CONTENT] followed by [JAPANESE CONTENT]."
            ;;
        "ko")
            language_instruction="After each English section, provide Korean translation in the same format. Use format: [ENGLISH CONTENT] followed by [KOREAN CONTENT]."
            ;;
        "fr")
            language_instruction="After each English section, provide French translation in the same format. Use format: [ENGLISH CONTENT] followed by [FRENCH CONTENT]."
            ;;
        "de")
            language_instruction="After each English section, provide German translation in the same format. Use format: [ENGLISH CONTENT] followed by [GERMAN CONTENT]."
            ;;
        "es")
            language_instruction="After each English section, provide Spanish translation in the same format. Use format: [ENGLISH CONTENT] followed by [SPANISH CONTENT]."
            ;;
        "pt")
            language_instruction="After each English section, provide Portuguese translation in the same format. Use format: [ENGLISH CONTENT] followed by [PORTUGUESE CONTENT]."
            ;;
        *)
            language_instruction=""
            ;;
    esac
    
    cat << EOF
Please review this code changes from branch '$current_branch' compared to '$target_branch'.

COMMITS:
$commit_list

CHANGED FILES:
$changed_files
$([ -n "$convention_content" ] && echo "
TEAM CONVENTIONS:
\`\`\`
$convention_content
\`\`\`
")
$([ -n "$api_changes" ] && echo "
API ENDPOINT ANALYSIS:
\`\`\`
$api_changes
\`\`\`
")
GIT DIFF:
\`\`\`diff
$git_diff
\`\`\`

Please provide a concise code review following EXACTLY this format. Be brief and specific.
$([ -n "$language_instruction" ] && echo "$language_instruction")
$([ -n "$convention_content" ] && echo "IMPORTANT: Since team conventions are provided, carefully analyze the code changes against these conventions and identify specific violations in the Convention Violations section. Look for naming conventions, code structure, testing requirements, documentation standards, etc.")
$([ -n "$api_changes" ] && echo "IMPORTANT: Use the API ENDPOINT ANALYSIS section above to accurately identify new, modified, or deleted API endpoints. Do not guess or infer endpoints - only use what is explicitly shown in the analysis.")

1. Changes:
- Commits:
  [List key commits with brief description]
- Files:
  [List main file categories and their purpose]
- Summary:
  - Scope: [Describe the scope based on number of files and areas affected]
  - Complexity: [Low/Medium/High - assess technical complexity]
  - Risk Level: [Low/Medium/High - assess deployment and operational risks]
  - Deployment Impact: [Describe coordination requirements and potential issues]
$([ -n "$convention_content" ] && echo "- Convention Violations:
  - List specific code changes that violate team conventions with file names and line references
  - Example: \"gw/service.go: Function 'processData' uses snake_case instead of camelCase (violates Go Guidelines)\"
  - Example: \"sss/repository.go: Missing error handling for database operation (violates error handling convention)\"
  - If no violations found, state: \"No major convention violations detected\"
")

2. Impact:
[Provide comprehensive analysis of system impact. Include detailed breakdown:]
- API Endpoints: 
$([ -n "$api_changes" ] && echo "  - Use the API ENDPOINT ANALYSIS section above as the primary source for endpoint information
  - Format each endpoint as: METHOD /path - Brief description
  - Example: POST /customer-products/:id/analysis - Generates new AI analysis
  - Example: GET /customer-products/:id/analysis - Retrieves AI analysis result
  - Do not include code quotes or technical details, only the clean endpoint format
  - If analysis shows no changes, state: \"No API endpoint changes detected\"" || echo "  - CRITICAL INSTRUCTION: ONLY extract endpoints that you can see EXPLICITLY in the Git diff of routes.go files
  - Format each endpoint as: METHOD /path - Brief description
  - Example: POST /customer-products/:id/analysis - Generates new AI analysis
  - Example: GET /customer-products/:id/analysis - Retrieves AI analysis result
  - Do not include code quotes or technical details, only the clean endpoint format
  - If you cannot see the exact route definition in the provided Git diff, DO NOT list any endpoints
  - If no route changes are visible in the diff, state: \"No API endpoint changes detected\"")
- Database Changes:
  - New tables: List all newly created tables with key columns
  - Table alterations: Detail ALTER TABLE statements and column changes
  - Migrations: List migration files and their purposes
  - Indexes: Any new indexes or constraints added
- Microservices Impact:
  - Primary services: Which services contain the main changes
  - Secondary services: Which services are affected by integration
  - Data flow: How data flows between affected services
  - Service dependencies: New or changed service-to-service calls
- Dependencies & Libraries:
  - New external libraries: List added dependencies
  - Version updates: Any library version changes
  - Configuration changes: New environment variables or configs
- Breaking Changes:
  - API compatibility: Any backwards incompatible API changes
  - Database schema: Schema changes that affect existing data
  - Client impact: How changes affect frontend/mobile clients
  - Deployment considerations: Rolling update compatibility

3. Clean code:
[List specific code quality issues with examples]

4. Performance:
[Identify performance concerns and optimization opportunities]

5. Other:
[Security, testing, documentation, deployment concerns]

Keep responses detailed for Impact section, concise for others. Focus on actionable insights.
EOF
}

# Generate default filename for review
generate_review_filename() {
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    echo "code-review-${timestamp}.md"
}

# Create review report file
create_review_file() {
    local target_branch="$1"
    local changed_files="$2"
    local review_content="$3"
    local output_file="$4"
    local current_branch=$(git branch --show-current)
    local review_date=$(date +"%Y-%m-%d %H:%M:%S")
    local project_name=$(basename "$(git rev-parse --show-toplevel)")
    
    # Get additional git info first
    local current_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "N/A")
    local commit_message=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "N/A")
    local author=$(git log -1 --pretty=format:"%an" 2>/dev/null || echo "N/A")
    local changed_files_count=$(echo "$changed_files" | wc -l | tr -d ' ')
    
    # Clean the review content by removing IDE errors and markdown formatting
    local cleaned_content=$(echo "$review_content" | \
        grep -v "\[ERROR\].*IDEClient" | \
        grep -v "Failed to connect to IDE companion extension" | \
        grep -v "Please ensure the extension is running" | \
        grep -v "To install the extension, run /ide install" | \
        grep -v "Loaded cached credentials" | \
        sed 's/\*\*\([^*]*\)\*\*/\1/g' | \
        sed 's/`\([^`]*\)`/\1/g' | \
        sed 's/^\s*```.*//g' | \
        sed '/^```$/d' | \
        sed '/^$/N;/^\n$/d' | \
        sed 's/^[[:space:]]*$//' | \
        awk 'NF || prev_nf {print} {prev_nf=NF}'
    )
    
    cat > "$output_file" << EOF
# 🔍 AI Code Review Report

## 📋 Review Information
- **Project:** $project_name
- **Branch:** \`$current_branch\`
- **Target:** \`$target_branch\`
- **Commit:** \`$current_commit\` - $commit_message
- **Author:** $author
- **Date:** $review_date
- **Files Changed:** $changed_files_count
- **Tool:** AI Code Review Tool v$VERSION

---

## 📁 Changed Files
\`\`\`
$changed_files
\`\`\`

---

## 🤖 AI Analysis

$cleaned_content

---
*Generated by [AI Code Review Tool](https://github.com/your-repo/review-code) on $review_date*
EOF
}

# Run code review
run_code_review() {
    local target_branch="$1"
    local save_to_file="$2"
    local no_save="$3"
    local convention_file="$4"
    local language="$5"
    
    print_header "Starting AI Code Review against '$target_branch'"
    
    # Check git repository
    if ! check_git_repo; then
        return 1
    fi
    
    # Check dependencies
    if ! check_dependencies; then
        return 1
    fi
    
    # Check authentication
    if ! check_auth_setup; then
        return 1
    fi
    
    # Read convention file if provided
    local convention_content=""
    if [ -n "$convention_file" ]; then
        if [ -f "$convention_file" ]; then
            print_info "Reading team convention from: $convention_file"
            convention_content=$(cat "$convention_file")
        else
            print_warning "Convention file not found: $convention_file"
        fi
    fi
    
    # Check git status
    if ! check_git_status; then
        return 1
    fi
    
    # Check target branch
    if ! check_target_branch "$target_branch"; then
        return 1
    fi
    
    # Get changed files
    print_info "Getting list of changed files..."
    local changed_files=$(get_changed_files "$target_branch")
    
    if [ -z "$changed_files" ]; then
        print_warning "No changes found between current branch and '$target_branch'"
        return 0
    fi
    
    print_success "Found changes in the following files:"
    echo "$changed_files" | sed 's/^/  /'
    echo ""
    
    # Get git diff
    print_info "Getting detailed changes..."
    local git_diff=$(get_git_diff "$target_branch")
    
    # Extract API changes from modules folder
    print_info "Analyzing API changes..."
    local api_changes=$(extract_api_changes "$target_branch")
    
    # Create review prompt
    local prompt=$(create_review_prompt "$changed_files" "$git_diff" "$target_branch" "$convention_content" "$api_changes" "$language")
    
    # Run Gemini review
    print_header "Running AI Code Review..."
    echo ""
    
    # Capture review output
    local review_output
    review_output=$(gemini -p "$prompt" 2>&1)
    
    # Filter out IDE connection errors and other noise
    local filtered_output=$(echo "$review_output" | grep -v "\[ERROR\] \[IDEClient\]" | grep -v "Loaded cached credentials" | sed '/^$/d')
    
    # Clean markdown formatting for terminal display
    local clean_output=$(echo "$filtered_output" | \
        sed 's/\*\*\([^*]*\)\*\*/\1/g' | \
        sed 's/`\([^`]*\)`/\1/g' | \
        sed 's/^\s*```.*//g' | \
        sed '/^```$/d')
    
    # Display formatted review output
    echo ""
    echo "╭─────────────────────────────────────────────────────────────────╮"
    echo "│                          📋 CODE REVIEW REPORT                  │"
    echo "╰─────────────────────────────────────────────────────────────────╯"
    echo ""
    
    # Process and format each section with colors
    echo "$clean_output" | while IFS= read -r line; do
        case "$line" in
            "1. Changes:")
                echo -e "\033[1;34m🔄 1. CHANGES\033[0m"
                echo "────────────────────────────────────────────────────────────────"
                ;;
            "2. Impact:")
                echo ""
                echo -e "\033[1;31m⚡ 2. IMPACT\033[0m"
                echo "────────────────────────────────────────────────────────────────"
                ;;
            "3. Clean code:")
                echo ""
                echo -e "\033[1;32m✨ 3. CLEAN CODE\033[0m"
                echo "────────────────────────────────────────────────────────────────"
                ;;
            "4. Performance:")
                echo ""
                echo -e "\033[1;33m⚡ 4. PERFORMANCE\033[0m"
                echo "────────────────────────────────────────────────────────────────"
                ;;
            "5. Other:")
                echo ""
                echo -e "\033[1;35m📝 5. OTHER\033[0m"
                echo "────────────────────────────────────────────────────────────────"
                ;;
            "- Commits:"*)
                echo -e "\033[0;36m  📝 $line\033[0m"
                ;;
            "- Files:"*)
                echo -e "\033[0;36m  📁 $line\033[0m"
                ;;
            *)
                # Regular content with proper indentation and highlighting
                if [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
                    # Bullet points - highlight key terms
                    local formatted_line="$line"
                    # Highlight specific terms
                    formatted_line=$(echo "$formatted_line" | sed 's/\bSecurity:\b/🔐 Security:/g')
                    formatted_line=$(echo "$formatted_line" | sed 's/\bTesting:\b/🧪 Testing:/g')
                    formatted_line=$(echo "$formatted_line" | sed 's/\bDeployment:\b/🚀 Deployment:/g')
                    formatted_line=$(echo "$formatted_line" | sed 's/\bGlobal Singleton:\b/⚠️  Global Singleton:/g')
                    formatted_line=$(echo "$formatted_line" | sed 's/\bBrittle File Paths:\b/⚠️  Brittle File Paths:/g')
                    formatted_line=$(echo "$formatted_line" | sed 's/\bConfiguration:\b/⚙️  Configuration:/g')
                    formatted_line=$(echo "$formatted_line" | sed 's/\bDatabase Migration Lock:\b/⚠️  Database Migration Lock:/g')
                    formatted_line=$(echo "$formatted_line" | sed 's/\bPotential N+1 Queries:\b/⚠️  Potential N+1 Queries:/g')
                    formatted_line=$(echo "$formatted_line" | sed 's/\bBranching Strategy:\b/🌿 Branching Strategy:/g')
                    echo -e "\033[0;90m    $formatted_line\033[0m"
                else
                    # Regular text
                    echo -e "\033[0;37m  $line\033[0m"
                fi
                ;;
        esac
    done
    
    echo ""
    echo "╭─────────────────────────────────────────────────────────────────╮"
    echo "│                        ✅ REVIEW COMPLETED                       │"
    echo "╰─────────────────────────────────────────────────────────────────╯"
    echo ""
    
    # Save to file if requested
    if [ "$no_save" != "true" ]; then
        local output_file
        if [ -n "$save_to_file" ]; then
            output_file="$save_to_file"
        else
            output_file=$(generate_review_filename)
        fi
        
        print_info "Saving review to: $output_file"
        create_review_file "$target_branch" "$changed_files" "$review_output" "$output_file"
        
        if [ $? -eq 0 ]; then
            print_success "Review saved to: $output_file"
        else
            print_error "Failed to save review to file"
        fi
    fi
    
    print_success "Code review completed!"
}

# Setup function
setup_tool() {
    print_header "Setting up AI Code Review Tool"
    
    # Check if we're in a git repo
    if ! check_git_repo; then
        print_info "Please run this setup in a git repository"
        return 1
    fi
    
    # Check dependencies
    if ! check_dependencies; then
        return 1
    fi
    
    # Check/setup authentication
    if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
        echo ""
        read -p "Enter your Google Cloud Project ID: " project_id
        if [ -n "$project_id" ]; then
            export GOOGLE_CLOUD_PROJECT="$project_id"
            echo "export GOOGLE_CLOUD_PROJECT=\"$project_id\"" >> ~/.zshrc 2>/dev/null || echo "export GOOGLE_CLOUD_PROJECT=\"$project_id\"" >> ~/.bashrc
            print_success "Project ID saved to shell profile"
        else
            print_error "Project ID is required"
            return 1
        fi
    fi
    
    # Test authentication
    if ! check_auth_setup; then
        print_info "Please run: gcloud auth login"
        return 1
    fi
    
    print_success "Setup completed successfully!"
    echo ""
    print_info "You can now run: $SCRIPT_NAME --target main"
}

# Main function
main() {
    local target_branch=""
    local save_to_file=""
    local no_save="false"
    local convention_file=""
    local language=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "$SCRIPT_NAME version $VERSION"
                exit 0
                ;;
            --target)
                target_branch="$2"
                shift 2
                ;;
            --save-to)
                save_to_file="$2"
                shift 2
                ;;
            --no-save)
                no_save="true"
                shift
                ;;
            --convention)
                convention_file="$2"
                shift 2
                ;;
            --language)
                language="$2"
                # Validate language code
                case "$language" in
                    vi|zh|ja|ko|fr|de|es|pt)
                        ;;
                    *)
                        print_error "Unsupported language: $language"
                        print_info "Supported languages: vi (Vietnamese), zh (Chinese), ja (Japanese), ko (Korean), fr (French), de (German), es (Spanish), pt (Portuguese)"
                        exit 1
                        ;;
                esac
                shift 2
                ;;
            --setup)
                setup_tool
                exit $?
                ;;
            *)
                print_error "Unknown option: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done
    
    # Check if target branch is provided
    if [ -z "$target_branch" ]; then
        print_error "Target branch is required"
        echo ""
        show_help
        exit 1
    fi
    
    # Run code review
    run_code_review "$target_branch" "$save_to_file" "$no_save" "$convention_file" "$language"
}

# Run main function with all arguments
main "$@"
