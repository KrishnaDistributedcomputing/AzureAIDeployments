# SDD Lab Worksheet

## Lab 1: Write a Feature Spec (15 minutes)

### Scenario
You are building a deployment approval endpoint that validates required architecture fields before merge.

### Tasks
1. Define objective and scope.
2. List assumptions and out-of-scope items.
3. Add functional requirements.
4. Add non-functional requirements (security, performance, reliability).
5. Add dependencies and risks.
6. Write rollback strategy.
7. Write acceptance criteria using measurable statements.

### Completion Checklist
- Scope and non-scope are explicit.
- Every requirement is testable.
- No ambiguous terms like "fast" or "user friendly" without thresholds.
- At least one security and one reliability criterion exist.

## Lab 2: Build From the Spec (15 minutes)

### Tasks
1. Convert each requirement into implementation tasks.
2. Define a test for each acceptance criterion.
3. Build traceability table.
4. Mark pass/fail evidence status.

### Traceability Table Template
| Requirement ID | Requirement Summary | Code Task | Test Case | Evidence Link | Status |
|---|---|---|---|---|---|
| FR-01 |  |  |  |  |  |
| FR-02 |  |  |  |  |  |
| NFR-01 |  |  |  |  |  |

### Completion Checklist
- Every requirement has at least one task.
- Every acceptance criterion has at least one test.
- Missing dependencies are flagged before release.
- Evidence is attached for all gate checks.

## Post-Lab Reflection
1. Which requirement was hardest to make measurable?
2. Which missing dependency was discovered only because of the spec?
3. What release risk did the gates prevent?