#!/bin/bash

# Test script for fetch_pending_comments.sh improvements
# Tests all three input options and error cases

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FETCH_SCRIPT="$SCRIPT_DIR/scripts/fetch_pending_comments.sh"
TEST_DIR="/tmp/pr_comments_test_$$"

# Colors for output
PASS='\033[0;32m'
FAIL='\033[0;31m'
INFO='\033[0;36m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

print_pass() {
    echo -e "${PASS}✓ PASS${NC}: $1"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${FAIL}✗ FAIL${NC}: $1"
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${INFO}ℹ INFO${NC}: $1"
}

print_test_header() {
    echo ""
    echo -e "${INFO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${INFO}TEST: $1${NC}"
    echo -e "${INFO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Verify script exists
if [[ ! -f "$FETCH_SCRIPT" ]]; then
    echo "Error: Script not found at $FETCH_SCRIPT"
    exit 1
fi

# Make sure script is executable
chmod +x "$FETCH_SCRIPT"

# Create test directory
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

print_test_header "1. Test Option B (GitHub URL)"
((TESTS_RUN++))
if bash "$FETCH_SCRIPT" "https://github.com/hugcanada/insurfactapps/pull/216" > /dev/null 2>&1; then
    print_pass "Option B: GitHub URL works from non-git directory"
else
    print_fail "Option B: GitHub URL should work from anywhere"
fi

print_test_header "2. Test Option C (Explicit owner/repo/number)"
((TESTS_RUN++))
if bash "$FETCH_SCRIPT" hugcanada insurfactapps 216 > /dev/null 2>&1; then
    print_pass "Option C: Explicit owner/repo/number works"
else
    print_fail "Option C: Explicit owner/repo/number should work"
fi

print_test_header "3. Test Option A (PR number only) from non-git directory"
((TESTS_RUN++))
OUTPUT=$( bash "$FETCH_SCRIPT" 216 2>&1 || true )
if echo "$OUTPUT" | grep -q "not in a git repository\|couldn't auto-detect"; then
    print_pass "Option A: Clear error message when not in git repo"
else
    print_fail "Option A: Should show clear error when not in git repo"
    echo "Got output: $OUTPUT"
fi

print_test_header "4. Test Option A (PR number only) from git repo"
((TESTS_RUN++))
# The insurfactapps repo is located at a known path
REPO_ROOT="/Users/hd/work/prj/insurfact/insurfactapps"
if [[ ! -d "$REPO_ROOT/.git" ]]; then
    print_fail "Option A: Could not find insurfactapps repo at $REPO_ROOT"
else
    cd "$REPO_ROOT"
    if bash "$FETCH_SCRIPT" 216 > /dev/null 2>&1; then
        print_pass "Option A: PR number auto-detection works from git repo"
    else
        print_fail "Option A: PR number should work from git repo"
    fi
fi

print_test_header "5. Test invalid PR number format"
((TESTS_RUN++))
OUTPUT=$( bash "$FETCH_SCRIPT" "abc" 2>&1 || true )
if echo "$OUTPUT" | grep -q "Invalid input format"; then
    print_pass "Error handling: Invalid PR number format rejected"
else
    print_fail "Error handling: Should reject non-numeric PR numbers"
fi

print_test_header "6. Test invalid number of arguments"
((TESTS_RUN++))
OUTPUT=$( bash "$FETCH_SCRIPT" owner repo 123 extra 2>&1 || true )
if echo "$OUTPUT" | grep -q "Invalid number of arguments\|Expected 1 or 3"; then
    print_pass "Error handling: Invalid argument count rejected"
else
    print_fail "Error handling: Should reject invalid argument count"
fi

print_test_header "7. Test no arguments"
((TESTS_RUN++))
OUTPUT=$( bash "$FETCH_SCRIPT" 2>&1 || true )
if echo "$OUTPUT" | grep -q "Missing arguments\|Usage"; then
    print_pass "Error handling: No arguments shows help"
else
    print_fail "Error handling: Should show help when no arguments given"
fi

print_test_header "8. Test malformed URL"
((TESTS_RUN++))
OUTPUT=$( bash "$FETCH_SCRIPT" "https://github.com/invalid-url" 2>&1 || true )
if echo "$OUTPUT" | grep -q "Invalid input format"; then
    print_pass "Error handling: Malformed URL rejected"
else
    print_fail "Error handling: Should reject malformed URLs"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"

# Summary
echo ""
echo -e "${INFO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${INFO}TEST SUMMARY${NC}"
echo -e "${INFO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${PASS}$TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "Tests failed: ${FAIL}$TESTS_FAILED${NC}"
else
    echo -e "Tests failed: ${PASS}0${NC}"
fi
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${PASS}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${FAIL}✗ Some tests failed${NC}"
    exit 1
fi
