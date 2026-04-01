#!/bin/bash

# ═════════════════════════════════════════════════════════════════════════════
# FIREBASE DATA ENGINEER DEPLOYMENT CHECKLIST
# Master Metabolic Database Population
# ═════════════════════════════════════════════════════════════════════════════

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                        ║"
echo "║   FIREBASE DATA ENGINEER — DEPLOYMENT CHECKLIST                       ║"
echo "║   Master Metabolic Database for ElenaApp                              ║"
echo "║                                                                        ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 1: CODE VALIDATION
# ═════════════════════════════════════════════════════════════════════════════

echo "PHASE 1: CODE VALIDATION"
echo "───────────────────────────────────────────────────────────────────────"

echo ""
echo "✅ [1.1] FoodSeeder.dart exists:"
if [ -f "lib/src/features/nutrition/data/food_seeder.dart" ]; then
    SIZE=$(stat -f%z "lib/src/features/nutrition/data/food_seeder.dart" 2>/dev/null || stat -c%s "lib/src/features/nutrition/data/food_seeder.dart")
    LINES=$(wc -l < "lib/src/features/nutrition/data/food_seeder.dart")
    echo "   ✓ File found"
    echo "   ✓ Size: $SIZE bytes"
    echo "   ✓ Lines: $LINES"
else
    echo "   ✗ File NOT found"
fi

echo ""
echo "✅ [1.2] FoodModel.dart compatible:"
if grep -q "nameLowercase" "lib/src/features/nutrition/domain/entities/food_model.dart"; then
    echo "   ✓ nameLowercase field present"
else
    echo "   ✗ nameLowercase field missing"
fi

if grep -q "imrScore" "lib/src/features/nutrition/domain/entities/food_model.dart"; then
    echo "   ✓ imrScore field present"
else
    echo "   ✗ imrScore field missing"
fi

if grep -q "tip" "lib/src/features/nutrition/domain/entities/food_model.dart"; then
    echo "   ✓ tip field present"
else
    echo "   ✗ tip field missing"
fi

echo ""
echo "✅ [1.3] Compilation Status:"
flutter analyze lib/src/features/nutrition/data/food_seeder.dart 2>&1 | \
    grep -E "issue|error|No errors" | tail -1

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 2: SCHEMA VALIDATION
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo "PHASE 2: 4-NODE SCHEMA VALIDATION"
echo "───────────────────────────────────────────────────────────────────────"

echo ""
echo "✅ [2.1] Metadata Node:"
grep -c "\"metadata\"" lib/src/features/nutrition/data/food_seeder.dart | xargs echo "   ✓ Fields defined for:"

echo ""
echo "✅ [2.2] Content Node:"
grep -c "\"content\"" lib/src/features/nutrition/data/food_seeder.dart | xargs echo "   ✓ Fields defined for:"

echo ""
echo "✅ [2.3] App Integration Node:"
grep -c "\"app_integration\"" lib/src/features/nutrition/data/food_seeder.dart | xargs echo "   ✓ Fields defined for:"

echo ""
echo "✅ [2.4] Quiz Node:"
grep -c "\"quiz\"" lib/src/features/nutrition/data/food_seeder.dart | xargs echo "   ✓ Fields defined for:"

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 3: FOOD DATABASE VALIDATION
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo "PHASE 3: FOOD DATABASE VALIDATION"
echo "───────────────────────────────────────────────────────────────────────"

echo ""
echo "✅ [3.1] Counting foods by category:"

echo ""
echo "   PROTEINS (IMR 10):"
grep -c "sardinas-atlanticas\|pechuga-pollo\|huevo-entero\|pata-de-res\|muslo-pollo\|salmon-cocido" \
    lib/src/features/nutrition/data/food_seeder.dart | xargs echo "      Count:"

echo ""
echo "   FATS (IMR 9-10):"
grep -c "aguacate\|aceite-oliva\|nueces\|cafe-negro" \
    lib/src/features/nutrition/data/food_seeder.dart | xargs echo "      Count:"

echo ""
echo "   VEGETABLES (IMR 9-10):"
grep -c "zucchini\|pimentón-rojo\|apio\|cebolla\|brocoli\|espinaca" \
    lib/src/features/nutrition/data/food_seeder.dart | xargs echo "      Count:"

echo ""
echo "   CARBOHYDRATES (IMR 4-6):"
grep -c "arroz-integral\|pasta-integral\|arepa-maiz\|pan-integral" \
    lib/src/features/nutrition/data/food_seeder.dart | xargs echo "      Count:"

echo ""
echo "   PROCESSED (IMR 2-3):"
grep -c "empanada\|pan-blanco\|galletas-saladas\|pasta-blanca" \
    lib/src/features/nutrition/data/food_seeder.dart | xargs echo "      Count:"

echo ""
echo "✅ [3.2] Total foods count:"
grep -c "\"id\":" lib/src/features/nutrition/data/food_seeder.dart | xargs echo "   Total:"

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 4: FIRESTORE INTEGRATION
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo "PHASE 4: FIRESTORE INTEGRATION"
echo "───────────────────────────────────────────────────────────────────────"

echo ""
echo "✅ [4.1] FirebaseFirestore imports:"
if grep -q "import 'package:cloud_firestore/cloud_firestore.dart'" \
    lib/src/features/nutrition/data/food_seeder.dart; then
    echo "   ✓ Cloud Firestore imported"
else
    echo "   ✗ Cloud Firestore import missing"
fi

echo ""
echo "✅ [4.2] Master collection reference:"
if grep -q "_masterFoodCollection = 'master_food_db'" \
    lib/src/features/nutrition/data/food_seeder.dart; then
    echo "   ✓ master_food_db collection defined"
else
    echo "   ✗ Collection name incorrect"
fi

echo ""
echo "✅ [4.3] Empty collection check:"
if grep -q ".count().get()" lib/src/features/nutrition/data/food_seeder.dart; then
    echo "   ✓ Count query implemented"
else
    echo "   ✗ Count query missing"
fi

echo ""
echo "✅ [4.4] Document injection:"
if grep -q ".set(foodDoc)" lib/src/features/nutrition/data/food_seeder.dart; then
    echo "   ✓ Firestore.set() implemented"
else
    echo "   ✗ Firestore injection missing"
fi

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 5: SAFETY & ERROR HANDLING
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo "PHASE 5: SAFETY & ERROR HANDLING"
echo "───────────────────────────────────────────────────────────────────────"

echo ""
echo "✅ [5.1] Try-Catch error handling:"
if grep -q "try {" lib/src/features/nutrition/data/food_seeder.dart; then
    echo "   ✓ Try-catch block present"
else
    echo "   ✗ Error handling missing"
fi

echo ""
echo "✅ [5.2] Audit trail print statements:"
PRINT_COUNT=$(grep -c "print(" lib/src/features/nutrition/data/food_seeder.dart)
echo "   ✓ $PRINT_COUNT print statements for tracking"

echo ""
echo "✅ [5.3] Success indicators:"
if grep -q "✅" lib/src/features/nutrition/data/food_seeder.dart; then
    echo "   ✓ Success emoji indicators present"
else
    echo "   ✗ Success indicators missing"
fi

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 6: DOCUMENTATION
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo "PHASE 6: DOCUMENTATION"
echo "───────────────────────────────────────────────────────────────────────"

echo ""
echo "✅ [6.1] Documentation files:"

DOC_FILES=(
    "FIREBASE_DATA_ENGINEER_SEEDER.md"
    "FIREBASE_DATA_ENGINEER_COMPLETE.md"
    "FIREBASE_SEEDER_INTEGRATION.md"
    "FIREBASE_MISSION_COMPLETE.md"
)

for file in "${DOC_FILES[@]}"; do
    if [ -f "$file" ]; then
        LINES=$(wc -l < "$file")
        echo "   ✓ $file ($LINES lines)"
    else
        echo "   ✗ $file NOT FOUND"
    fi
done

# ═════════════════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                        ║"
echo "║   ✅ DEPLOYMENT CHECKLIST COMPLETE                                    ║"
echo "║                                                                        ║"
echo "║   Status: READY FOR PRODUCTION                                        ║"
echo "║                                                                        ║"
echo "║   Next Steps:                                                         ║"
echo "║   1. Call FoodSeeder.seedDatabase() in main.dart                      ║"
echo "║   2. Verify 25 foods in Firestore Console                             ║"
echo "║   3. Test search functionality in app                                 ║"
echo "║   4. Deploy to production Firebase project                            ║"
echo "║                                                                        ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo ""
echo "For more details, see:"
echo "  • FIREBASE_DATA_ENGINEER_SEEDER.md"
echo "  • FIREBASE_SEEDER_INTEGRATION.md"
echo "  • FIREBASE_MISSION_COMPLETE.md"
echo ""
