# SDD Quiz and Answer Key

## Quiz

1. Which statement best describes Spec-Driven Development?
- A. Write code first, document later.
- B. Define requirements and acceptance evidence before implementation.
- C. Avoid documentation for speed.
- D. Test only after release.

2. Which acceptance criterion is strongest?
- A. Response should be quick.
- B. API should be stable.
- C. 95th percentile response time must be under 300 ms at 200 RPS for 15 minutes.
- D. Endpoint should usually pass tests.

3. What is the primary value of a traceability matrix?
- A. Makes specs longer.
- B. Maps requirements to implementation and tests.
- C. Replaces code reviews.
- D. Removes need for QA.

4. Which is an anti-pattern in specs?
- A. Explicit non-functional constraints.
- B. Measurable release gates.
- C. Vague language without thresholds.
- D. Dependency declarations.

5. Why include rollback criteria in a spec?
- A. It is optional formatting.
- B. It reduces deployment risk and defines recovery behavior.
- C. It replaces monitoring.
- D. It avoids testing.

6. Which gate should be checked before merge?
- A. Requirement-to-test coverage.
- B. Marketing sign-off only.
- C. Team mood.
- D. Number of comments in pull request.

7. A requirement says "secure authentication". What is missing?
- A. Nothing.
- B. Measurable controls (for example protocol, token lifetime, failure handling).
- C. More adjectives.
- D. A diagram only.

8. What should happen if a requirement has no test coverage?
- A. Ship anyway.
- B. Mark as low priority.
- C. Block release or accept formally with risk owner.
- D. Delete requirement.

9. Which artifact is best for release readiness?
- A. Informal chat log.
- B. Gate checklist with objective pass/fail evidence.
- C. Verbal confirmation.
- D. Backlog screenshot.

10. Which sequence is most aligned with SDD?
- A. Implement -> guess requirements -> test
- B. Spec -> map tasks -> implement -> validate gates -> release
- C. Release -> document -> patch
- D. Test -> spec -> deploy

## Answer Key
1. B
2. C
3. B
4. C
5. B
6. A
7. B
8. C
9. B
10. B

## Scoring Guide
- 9-10 correct: Strong readiness to apply SDD immediately.
- 7-8 correct: Ready with minor coaching.
- 5-6 correct: Review acceptance criteria and gate workflow.
- Under 5: Repeat labs before applying in production delivery.