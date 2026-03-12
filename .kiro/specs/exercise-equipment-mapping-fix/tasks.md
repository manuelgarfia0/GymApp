# Implementation Plan

- [x] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Equipment Field Mapping Investigation
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the equipment field mapping bug exists
  - **Scoped PBT Approach**: Scope the property to concrete failing cases where API sends equipment field but DTO maps to null
  - Test that when API response contains equipment field with valid data, ExerciseDto.fromJson() correctly maps it to category property
  - Investigate actual API response structure by adding temporary logging to capture JSON structure
  - Verify if backend sends "equipment" field or "category" field in JSON response
  - Test with multiple exercise records to confirm consistency
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found (e.g., "API sends equipment: 'Barbell' but DTO.category is null")
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 1.1, 1.2, 2.1, 2.2_

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Non-Equipment Field Mapping
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-equipment fields (name, description, primaryMuscle, secondaryMuscles)
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements
  - Test that name field maps correctly from JSON to DTO
  - Test that description field maps correctly from JSON to DTO
  - Test that primaryMuscle and secondaryMuscles fields map correctly from JSON to DTO
  - Test that DTO to Entity conversion works correctly for all non-equipment fields
  - Property-based testing generates many test cases for stronger guarantees
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 3. Fix for equipment field mapping discrepancy

  - [x] 3.1 Implement the equipment field mapping fix
    - Analyze the actual API response structure from exploration test results
    - Update ExerciseDto.fromJson() method to correctly map equipment field
    - If backend sends "equipment": map json['equipment'] to category property
    - If backend sends "category": verify current mapping logic is correct
    - Implement fallback strategy to support both field names for API compatibility
    - Add validation logic to handle missing or null equipment fields gracefully
    - Update documentation comments to reflect correct field mapping
    - _Bug_Condition: isBugCondition(input) where API contains equipment field but DTO.category is null_
    - _Expected_Behavior: Equipment field from API correctly mapped to DTO.category property_
    - _Preservation: Name, description, primaryMuscle, secondaryMuscles mapping unchanged_
    - _Requirements: 1.1, 1.2, 2.1, 2.2, 3.1, 3.2, 3.3_

  - [x] 3.2 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Equipment Field Mapping Investigation
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
    - Verify that equipment field is now correctly mapped from API response to DTO
    - Confirm that equipment information displays correctly in UI
    - _Requirements: 2.1, 2.2_

  - [x] 3.3 Verify preservation tests still pass
    - **Property 2: Preservation** - Non-Equipment Field Mapping
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm that name, description, primaryMuscle, and secondaryMuscles still map correctly
    - Verify that DTO to Entity conversion continues working for all preserved fields
    - Ensure no regression in existing exercise loading functionality

- [x] 4. Checkpoint - Ensure all tests pass
  - Run all property-based tests to confirm complete fix
  - Verify equipment field displays correctly in Flutter UI
  - Confirm no regressions in existing exercise functionality
  - Test with multiple exercise records to ensure consistency
  - Ensure all tests pass, ask the user if questions arise