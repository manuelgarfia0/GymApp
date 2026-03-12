# Implementation Plan

- [x] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - JSON Content-Type Headers
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: For deterministic bugs, scope the property to the concrete failing case(s) to ensure reproducibility
  - Test that POST requests with JSON bodies send Content-Type 'application/json' (from Bug Condition in design)
  - Create test cases for login POST, register POST, and generic POST with JSON body
  - Inspect actual HTTP headers being sent by ApiClient
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found: Content-Type will be 'text/plain;charset=utf-8' instead of 'application/json'
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Non-JSON Request Behavior
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-buggy inputs (GET requests, requests without JSON bodies)
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements
  - Test that GET requests continue to work without Content-Type headers
  - Test that JWT token injection via Authorization header remains unchanged
  - Test that error handling and retry logic remain unchanged
  - Property-based testing generates many test cases for stronger guarantees
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 3. Fix for API Contract Content-Type Issue

  - [x] 3.1 Implement the ApiClient fix
    - Modify `lib/core/network/api_client.dart` to properly handle JSON Content-Type headers
    - Override the `post` method to ensure proper Content-Type handling for JSON requests
    - Add logic to detect when a request body contains JSON content
    - Implement explicit header setting for JSON requests that persists through HTTP request lifecycle
    - Add header validation to ensure Content-Type headers are correctly applied
    - Ensure backward compatibility for GET requests and other HTTP methods
    - _Bug_Condition: isBugCondition(input) where input.method == 'POST' AND input.hasJsonBody == true AND input.actualContentType == 'text/plain;charset=utf-8'_
    - _Expected_Behavior: POST requests with JSON bodies SHALL send Content-Type 'application/json'_
    - _Preservation: GET requests and non-JSON requests SHALL continue to work exactly as before_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_

  - [x] 3.2 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - JSON Content-Type Headers
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
    - Verify that POST requests with JSON bodies now send Content-Type 'application/json'
    - Verify that Spring Boot successfully processes requests with correct headers
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [x] 3.3 Verify preservation tests still pass
    - **Property 2: Preservation** - Non-JSON Request Behavior
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm GET requests continue to work without Content-Type headers
    - Confirm JWT token injection continues to work across all request types
    - Confirm error handling and other HTTP methods remain unchanged
    - Confirm all tests still pass after fix (no regressions)

- [x] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
  - Verify full login flow works with corrected Content-Type headers
  - Verify registration flow works with proper JSON Content-Type
  - Verify that authentication errors return appropriate HTTP status codes (401, 403) instead of 500