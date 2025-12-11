#!/usr/bin/env bash

set -euo pipefail

echo "=== Test Files Verification ==="
echo ""

echo "1. UAPI Test File:"
echo "   File: tests/test_uapi.bats"
echo "   Tests: $(grep -c "^@test" tests/test_uapi.bats)"
echo "   Status: $([ -x tests/test_uapi.bats ] && echo "Executable" || echo "Not executable")"
echo ""

echo "2. Validators Test File:"
echo "   File: tests/test_validators.bats"
echo "   Tests: $(grep -c "^@test" tests/test_validators.bats)"
echo "   Status: $([ -x tests/test_validators.bats ] && echo "Executable" || echo "Not executable")"
echo ""

echo "3. Fixture Files:"
echo "   Total: $(ls -1 tests/fixtures/uapi_*.json tests/fixtures/uapi_*.txt 2>/dev/null | wc -l)"
echo "   Database fixtures: $(ls -1 tests/fixtures/uapi_mysql_*.json 2>/dev/null | wc -l)"
echo "   Passenger fixtures: $(ls -1 tests/fixtures/uapi_passenger_*.json 2>/dev/null | wc -l)"
echo "   Error fixtures: $(ls -1 tests/fixtures/uapi_error_*.* 2>/dev/null | wc -l)"
echo ""

echo "4. Expected Implementation Files (should NOT exist yet):"
if [ -f scripts/uapi.sh ]; then
    echo "   ❌ scripts/uapi.sh EXISTS (should not exist in Red phase)"
else
    echo "   ✅ scripts/uapi.sh does not exist (correct for Red phase)"
fi

if [ -f scripts/validators.sh ]; then
    echo "   ❌ scripts/validators.sh EXISTS (should not exist in Red phase)"
else
    echo "   ✅ scripts/validators.sh does not exist (correct for Red phase)"
fi
echo ""

echo "5. Test Infrastructure:"
echo "   Logger: $([ -f scripts/logger.sh ] && echo "✅ Present" || echo "❌ Missing")"
echo "   Test helpers: $([ -f tests/helpers/test_helpers.bash ] && echo "✅ Present" || echo "❌ Missing")"
echo "   BATS support: $([ -d tests/libs/bats-support ] && echo "✅ Present" || echo "❌ Missing")"
echo "   BATS assert: $([ -d tests/libs/bats-assert ] && echo "✅ Present" || echo "❌ Missing")"
echo ""

echo "=== Summary ==="
TOTAL_TESTS=$(($(grep -c "^@test" tests/test_uapi.bats) + $(grep -c "^@test" tests/test_validators.bats)))
echo "Total tests created: ${TOTAL_TESTS}"
echo "Expected to FAIL: ${TOTAL_TESTS} (Red phase - no implementation)"
echo ""
echo "✅ Stage 4 (Test Writing) is COMPLETE"
echo "⏭️  Next: Stage 5 (Implementation) to make tests pass"
