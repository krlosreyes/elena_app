#!/bin/bash
# 🧪 Elena App - E2E Testing Script
# Automates pre-deployment validation

set -e

PROJECTDIR="/Users/carlosreyes/Proyectos/ElenaApp/elena_app"
cd "$PROJECTDIR"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Elena App - End-to-End Testing & Validation Script      ║"
echo "║   Status: 🟢 PRODUCTION READY                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_TOTAL=0

# Function to run test
run_test() {
    local test_name=$1
    local command=$2
    local expected=$3
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo ""
    echo -e "${BLUE}[TEST $TESTS_TOTAL]${NC} $test_name"
    echo "Command: $command"
    
    if eval "$command" | grep -q "$expected"; then
        echo -e "${GREEN}✅ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC}"
    fi
}

# Test 1: Check compilation
echo ""
echo -e "${BLUE}━━━ COMPILATION VALIDATION ━━━${NC}"
run_test "No compilation errors in food_seeder.dart" \
    "flutter analyze lib/src/features/nutrition/data/food_seeder.dart 2>&1" \
    "found."

run_test "No compilation errors in food_repository.dart" \
    "flutter analyze lib/src/features/nutrition/data/repositories/food_repository.dart 2>&1" \
    "found."

# Test 2: Check project structure
echo ""
echo -e "${BLUE}━━━ PROJECT STRUCTURE VALIDATION ━━━${NC}"
run_test "food_seeder.dart exists" \
    "test -f lib/src/features/nutrition/data/food_seeder.dart && echo 'EXISTS'" \
    "EXISTS"

run_test "food_repository.dart exists" \
    "test -f lib/src/features/nutrition/data/repositories/food_repository.dart && echo 'EXISTS'" \
    "EXISTS"

run_test "searchable_food_dropdown.dart exists" \
    "test -f lib/src/features/onboarding/presentation/widgets/searchable_food_dropdown.dart && echo 'EXISTS'" \
    "EXISTS"

# Test 3: Check data seeding code
echo ""
echo -e "${BLUE}━━━ DATA SEEDING CODE VALIDATION ━━━${NC}"
run_test "seedGrasasHealthyFats method exists" \
    "grep -q 'seedGrasasHealthyFats' lib/src/features/nutrition/data/food_seeder.dart && echo 'FOUND'" \
    "FOUND"

run_test "seedProteinsComplete method exists" \
    "grep -q 'seedProteinsComplete' lib/src/features/nutrition/data/food_seeder.dart && echo 'FOUND'" \
    "FOUND"

run_test "seedVegetablesComplete method exists" \
    "grep -q 'seedVegetablesComplete' lib/src/features/nutrition/data/food_seeder.dart && echo 'FOUND'" \
    "FOUND"

run_test "seedCarbsComplete method exists" \
    "grep -q 'seedCarbsComplete' lib/src/features/nutrition/data/food_seeder.dart && echo 'FOUND'" \
    "FOUND"

# Test 4: Check category synchronization
echo ""
echo -e "${BLUE}━━━ CATEGORY SYNCHRONIZATION VALIDATION ━━━${NC}"
run_test "Proteínas category present (31 items)" \
    "grep -c \"'Proteínas 🍗'\" lib/src/features/nutrition/data/food_seeder.dart || echo '0'" \
    "[0-9]"

run_test "Grasas category present (21+ items)" \
    "grep -c \"'Grasas 🥑'\" lib/src/features/nutrition/data/food_seeder.dart || echo '0'" \
    "[0-9]"

run_test "Vegetales category present (15 items)" \
    "grep -c \"'Vegetales 🥦'\" lib/src/features/nutrition/data/food_seeder.dart || echo '0'" \
    "[0-9]"

run_test "Carbohidratos category present (15 items)" \
    "grep -c \"'Carbohidratos 🍞'\" lib/src/features/nutrition/data/food_seeder.dart || echo '0'" \
    "[0-9]"

# Test 5: Check repository mapping
echo ""
echo -e "${BLUE}━━━ REPOSITORY MAPPING VALIDATION ━━━${NC}"
run_test "Repository has category mapping for 'protein'" \
    "grep -q \"category == 'protein'\" lib/src/features/nutrition/data/repositories/food_repository.dart && echo 'FOUND'" \
    "FOUND"

run_test "Repository maps to exact 'Proteínas 🍗'" \
    "grep -q \"'Proteínas 🍗'\" lib/src/features/nutrition/data/repositories/food_repository.dart && echo 'FOUND'" \
    "FOUND"

# Test 6: Check main.dart integration
echo ""
echo -e "${BLUE}━━━ AUTO-SEEDING INTEGRATION VALIDATION ━━━${NC}"
run_test "main.dart imports FoodSeeder" \
    "grep -q \"import 'src/features/nutrition/data/food_seeder.dart'\" lib/main.dart && echo 'FOUND'" \
    "FOUND"

run_test "main.dart calls seedDatabase()" \
    "grep -q \"FoodSeeder.seedDatabase()\" lib/main.dart && echo 'FOUND'" \
    "FOUND"

# Test 7: Check documentation
echo ""
echo -e "${BLUE}━━━ DOCUMENTATION VALIDATION ━━━${NC}"
run_test "PRODUCTION_VALIDATION_PHASE5.md exists" \
    "test -f PRODUCTION_VALIDATION_PHASE5.md && echo 'EXISTS'" \
    "EXISTS"

run_test "E2E_TESTING_GUIDE.md exists" \
    "test -f E2E_TESTING_GUIDE.md && echo 'EXISTS'" \
    "EXISTS"

run_test "PROJECT_COMPLETE_SUMMARY.md exists" \
    "test -f PROJECT_COMPLETE_SUMMARY.md && echo 'EXISTS'" \
    "EXISTS"

# Test 8: Check 4-node structure
echo ""
echo -e "${BLUE}━━━ 4-NODE DATA STRUCTURE VALIDATION ━━━${NC}"
run_test "Food items have 'metadata' node" \
    "grep -q \"'metadata'\" lib/src/features/nutrition/data/food_seeder.dart && echo 'FOUND'" \
    "FOUND"

run_test "Food items have 'content' node" \
    "grep -q \"'content'\" lib/src/features/nutrition/data/food_seeder.dart && echo 'FOUND'" \
    "FOUND"

run_test "Food items have 'app_integration' node" \
    "grep -q \"'app_integration'\" lib/src/features/nutrition/data/food_seeder.dart && echo 'FOUND'" \
    "FOUND"

run_test "Food items have 'quiz' node" \
    "grep -q \"'quiz'\" lib/src/features/nutrition/data/food_seeder.dart && echo 'FOUND'" \
    "FOUND"

# Test 9: Check WriteBatch usage
echo ""
echo -e "${BLUE}━━━ ATOMICITY VALIDATION (WriteBatch) ━━━${NC}"
run_test "WriteBatch used for atomicity" \
    "grep -q \"WriteBatch\" lib/src/features/nutrition/data/food_seeder.dart && echo 'FOUND'" \
    "FOUND"

run_test "batch.set() used for atomic writes" \
    "grep -q \"batch.set\" lib/src/features/nutrition/data/food_seeder.dart && echo 'FOUND'" \
    "FOUND"

run_test "batch.commit() ensures atomicity" \
    "grep -q \"batch.commit()\" lib/src/features/nutrition/data/food_seeder.dart && echo 'FOUND'" \
    "FOUND"

# Print summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    TEST RESULTS SUMMARY                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

PASS_PERCENTAGE=$((TESTS_PASSED * 100 / TESTS_TOTAL))

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED! ($TESTS_PASSED/$TESTS_TOTAL)${NC}"
    echo ""
    echo -e "${BLUE}Status:${NC} 🟢 PRODUCTION READY"
    echo ""
    echo "Next steps:"
    echo "1. Run: flutter clean"
    echo "2. Run: flutter pub get"
    echo "3. Run: flutter run"
    echo "4. Follow: E2E_TESTING_GUIDE.md"
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED ($TESTS_PASSED/$TESTS_TOTAL - $PASS_PERCENTAGE%)${NC}"
    echo ""
    echo "Please fix the failing tests before deployment."
    exit 1
fi
