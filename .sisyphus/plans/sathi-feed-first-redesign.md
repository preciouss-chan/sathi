# Sathi Feed-First Redesign

## TL;DR

> **Quick Summary**: Redesign Sathi from a stacked dashboard into a modern feed-first social wellbeing app where friends’ shared posts appear on home, weekly check-in becomes a compact action, connections move into profile/settings, and photo/voice creation is unified in one composer.
>
> **Deliverables**:
> - Feed-first home screen with compact personal status and shared content timeline
> - Unified create composer for optional photo and optional voice
> - Profile/settings surface containing connections management
> - Updated shared-content rendering on home instead of Connections-only visibility
>
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 3 waves
> **Critical Path**: IA/navigation redesign → unified shared-content model/rendering → unified composer → final polish/QA

---

## Context

### Original Request
Redesign the app so it feels modern, removes redundant home intro copy, surfaces friends’ shared photos/posts on the home screen, de-emphasizes large connections and weekly check-in sections, improves theme/colors, and combines photo + voice creation into one composer.

### Interview Summary
**Key Discussions**:
- Home should be **feed-first**.
- Friends’ shared content should be emphasized most.
- Weekly check-in should remain on home only as a **compact chip/action**.
- Connections should move into a **profile/settings area**.
- Create flow should be **one composer** where photo and voice are each optional.
- Verification should be **tests after + agent QA**.

**Research Findings**:
- Existing architecture already has centralized `AppState` and service-based sharing, so this is primarily a UI/IA redesign rather than a backend rewrite.
- Shared updates currently render only in Connections; that rendering path can be reused for a home feed.
- Current large-card home layout is the main source of visual heaviness and redundancy.

### Metis Review
**Identified Gaps** (addressed internally due Metis timeout):
- Need explicit guardrail against accidental backend scope explosion → keep backend reuse-first, no new realtime/chat system.
- Need explicit acceptance criteria for feed precedence and compact weekly check-in treatment.
- Need guardrail against leaving duplicate legacy entry points that undermine the new IA.

---

## Work Objectives

### Core Objective
Transform Sathi into a cleaner, feed-first experience that prioritizes friends’ shared content on home while keeping wellbeing actions fast, compact, and demo-ready.

### Concrete Deliverables
- Redesigned home screen with shared feed as primary content
- Compact weekly check-in action on home
- Unified create composer replacing separate photo/voice-first mental model
- Profile/settings-based connections access
- Updated modern visual theme and icon-forward navigation

### Definition of Done
- [ ] Home no longer uses the redundant oversized intro as a primary hero
- [ ] Shared updates appear on home
- [ ] Connections no longer occupy large home sections
- [ ] Weekly check-in is compact and accessible from home
- [ ] User can create a post with photo, voice, or both from one composer
- [ ] Build and analyzer pass

### Must Have
- Feed-first home hierarchy
- Friends’ shared content visible on home
- One composer with optional media inputs
- Cleaner, more modern visual design

### Must NOT Have (Guardrails)
- No large new backend system or chat rebuild
- No duplicate primary flows that keep old IA alive alongside the new one
- No breaking of existing Firebase sharing foundation
- No clinical wording or diagnosis-style terminology

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed.

### Test Decision
- **Infrastructure exists**: Limited Flutter test scaffolding only
- **Automated tests**: Tests-after
- **Framework**: flutter test (where practical) + flutter analyze/build

### QA Policy
Every implementation task must include agent-executed QA scenarios.

- **Frontend/UI**: Launch app, navigate screens, validate visible hierarchy and controls
- **State/navigation**: Verify route entry points and back navigation behavior
- **Firebase-backed flows**: Validate shared-content surfaces still render after redesign

---

## Execution Strategy

### Parallel Execution Waves

Wave 1 (Start Immediately — IA + shared primitives):
├── Task 1: Home IA redesign spec + route map [deep]
├── Task 2: Shared feed item rendering abstraction [quick]
├── Task 3: Theme/color/token refresh [visual-engineering]
├── Task 4: Compact action/navigation pattern definition [visual-engineering]
└── Task 5: Connections relocation plan to profile/settings [quick]

Wave 2 (After Wave 1 — core implementation, max parallel):
├── Task 6: Feed-first home implementation (depends: 1,2,3,4) [visual-engineering]
├── Task 7: Unified create composer screen/flow (depends: 1,2,4) [deep]
├── Task 8: Weekly check-in compact home action integration (depends: 1,4) [quick]
├── Task 9: Profile/settings surface with connections entry (depends: 1,5) [quick]
└── Task 10: Legacy navigation cleanup and entry-point consolidation (depends: 6,7,8,9) [quick]

Wave 3 (After Wave 2 — polish + consistency):
├── Task 11: Feed card polish for voice/photo/check-in post types (depends: 6,7) [visual-engineering]
├── Task 12: Copy cleanup and redundant-header removal (depends: 6,9) [writing]
├── Task 13: Tests-after + analyzer/build verification (depends: 10,11,12) [quick]
└── Task 14: UX regression pass on sharing and home visibility (depends: 10,11,12) [unspecified-high]

Wave FINAL (After ALL tasks):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA / app walkthrough (unspecified-high)
└── Task F4: Scope fidelity check (deep)

Critical Path: 1 → 6 → 7 → 10 → 11 → 13/14 → F1-F4

### Dependency Matrix
- **1**: — → 6,7,8,9
- **2**: — → 6,7,11
- **3**: — → 6,11
- **4**: — → 6,7,8
- **5**: — → 9
- **6**: 1,2,3,4 → 10,11,12
- **7**: 1,2,4 → 10,11
- **8**: 1,4 → 10
- **9**: 1,5 → 10,12
- **10**: 6,7,8,9 → 13,14
- **11**: 6,7 → 13,14
- **12**: 6,9 → 13,14
- **13**: 10,11,12 → F1-F4
- **14**: 10,11,12 → F1-F4

### Agent Dispatch Summary
- **Wave 1**: T1 → deep, T2 → quick, T3-T4 → visual-engineering, T5 → quick
- **Wave 2**: T6 → visual-engineering, T7 → deep, T8-T10 → quick
- **Wave 3**: T11 → visual-engineering, T12 → writing, T13 → quick, T14 → unspecified-high

---

## TODOs

- [ ] 1. Define feed-first information architecture

  **What to do**:
  - Decide exact order of home elements: compact personal header, weekly chip, feed timeline, mini shortcuts
  - Define route/entry behavior for Home, Composer, Profile/Settings, Insights

  **Must NOT do**:
  - Keep the current oversized stacked-card dashboard as the primary structure

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: 6,7,8,9
  - **Blocked By**: None

  **References**:
  - `lib/src/screens/home_screen.dart` - current heavy home layout to replace
  - `lib/src/screens/connections_screen.dart` - current feed visibility location
  - `lib/src/app/sathi_app.dart` - route structure to update

  **Acceptance Criteria**:
  - [ ] New home IA documented in implementation choices
  - [ ] Old giant intro/header no longer primary hero in redesign

  **QA Scenarios**:
  ```
  Scenario: Home hierarchy matches feed-first design
    Tool: Flutter app run
    Steps:
      1. Launch home screen
      2. Observe first viewport contents
      3. Assert shared feed items are visible before large utility sections
    Expected Result: Feed is the dominant home content area
    Evidence: .sisyphus/evidence/task-1-home-hierarchy.txt

  Scenario: No legacy dashboard clutter
    Tool: Flutter app run
    Steps:
      1. Launch home
      2. Confirm no oversized redundant hero intro remains
    Expected Result: Intro is removed or compacted
    Evidence: .sisyphus/evidence/task-1-no-legacy-hero.txt
  ```

- [ ] 2. Create reusable shared feed item rendering layer

  **What to do**:
  - Extract a reusable display pattern for shared voice/photo/check-in/feed cards
  - Ensure shared content can render on home and secondary surfaces consistently

  **Must NOT do**:
  - Duplicate nearly identical rendering code across multiple screens

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: 6,7,11
  - **Blocked By**: None

  **References**:
  - `lib/src/screens/connections_screen.dart` - current shared update rendering
  - `lib/src/models/shared_update.dart` - feed payload model

  **Acceptance Criteria**:
  - [ ] Shared update cards can display all current post types consistently

- [ ] 3. Refresh visual theme and color system

  **What to do**:
  - Replace current palette/tone with a stronger modern theme that still feels safe and warm
  - Harmonize surfaces, accents, icon emphasis, and spacing

  **Must NOT do**:
  - Introduce harsh/neon styling that breaks emotional safety

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: 6,11
  - **Blocked By**: None

  **References**:
  - `lib/src/core/theme/app_theme.dart` - theme source of truth

  **Acceptance Criteria**:
  - [ ] Theme update applied consistently across redesigned surfaces

- [ ] 4. Define compact icon-driven action/navigation pattern

  **What to do**:
  - Replace large action sections with compact icon/button/chip patterns
  - Specify modern action density for home

  **Must NOT do**:
  - Leave large vertically stacked primary action blocks dominating home

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: 6,7,8
  - **Blocked By**: None

  **Acceptance Criteria**:
  - [ ] Home actions are icon-forward and compact

- [ ] 5. Relocate connections to profile/settings

  **What to do**:
  - Move connections discovery/management out of home emphasis
  - Keep access discoverable but secondary

  **Must NOT do**:
  - Leave connections as a large home section

  **Recommended Agent Profile**:
  - **Category**: `quick`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: 9
  - **Blocked By**: None

  **Acceptance Criteria**:
  - [ ] Connections accessible from profile/settings area

- [ ] 6. Implement feed-first home screen

  **What to do**:
  - Rebuild home around shared friend content timeline
  - Keep user pulse/check-in entry compact
  - Surface photos from friends directly on home

  **Must NOT do**:
  - Reintroduce legacy oversized sections

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2
  - **Blocks**: 10,11,12
  - **Blocked By**: 1,2,3,4

  **Acceptance Criteria**:
  - [ ] Home first viewport shows feed content prominently
  - [ ] Shared photos can appear on home
  - [ ] Weekly check-in appears as a small chip/action

- [ ] 7. Build one unified create composer

  **What to do**:
  - Merge separate mental model of voice/photo creation into one create surface
  - Allow user to attach photo, voice, or both

  **Must NOT do**:
  - Force both media types every time

  **Recommended Agent Profile**:
  - **Category**: `deep`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2
  - **Blocks**: 10,11
  - **Blocked By**: 1,2,4

  **Acceptance Criteria**:
  - [ ] Single composer exists
  - [ ] Photo-only, voice-only, and photo+voice combinations are supported

- [ ] 8. Compact weekly check-in integration

  **What to do**:
  - Convert weekly check-in entry on home into a compact chip/icon CTA
  - Preserve accessibility and discoverability

  **Must NOT do**:
  - Keep weekly check-in as a large primary home block

  **Recommended Agent Profile**:
  - **Category**: `quick`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2
  - **Blocks**: 10
  - **Blocked By**: 1,4

  **Acceptance Criteria**:
  - [ ] Weekly check-in reachable in one tap from home

- [ ] 9. Build profile/settings surface with connections entry

  **What to do**:
  - Add or adapt a profile/settings destination
  - Move connections management there

  **Must NOT do**:
  - Hide connections so deeply users cannot find them during demo

  **Recommended Agent Profile**:
  - **Category**: `quick`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2
  - **Blocks**: 10,12
  - **Blocked By**: 1,5

  **Acceptance Criteria**:
  - [ ] Connections accessible from profile/settings and no longer emphasized on home

- [ ] 10. Remove or consolidate legacy entry points

  **What to do**:
  - Clean routes/buttons so the new IA feels intentional
  - Remove redundant giant cards and unnecessary duplicated entrances

  **Must NOT do**:
  - Leave both old and new UX competing visually

  **Recommended Agent Profile**:
  - **Category**: `quick`

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential after Wave 2
  - **Blocks**: 13,14
  - **Blocked By**: 6,7,8,9

  **Acceptance Criteria**:
  - [ ] Navigation feels coherent with no major dead or duplicate primary paths

- [ ] 11. Polish feed cards for all content types

  **What to do**:
  - Ensure voice/photo/check-in items feel visually unified
  - Improve card hierarchy, spacing, badges/icons, and readability

  **Must NOT do**:
  - Use generic placeholder styling that feels unfinished

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocks**: 13,14
  - **Blocked By**: 6,7

  **Acceptance Criteria**:
  - [ ] Feed visually distinguishes content types without clutter

- [ ] 12. Cleanup copy and remove redundant intro messaging

  **What to do**:
  - Remove or compress redundant “tiny homesick companion” hero copy
  - Update labels to fit modern app tone and reduced clutter

  **Must NOT do**:
  - Reintroduce long explanatory text blocks on home

  **Recommended Agent Profile**:
  - **Category**: `writing`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocks**: 13,14
  - **Blocked By**: 6,9

  **Acceptance Criteria**:
  - [ ] Home copy is brief, modern, and non-redundant

- [ ] 13. Run tests-after, analyzer, and build verification

  **What to do**:
  - Run analyzer/build/tests where practical after redesign implementation
  - Fix regressions caused by route/layout consolidation

  **Recommended Agent Profile**:
  - **Category**: `quick`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocked By**: 10,11,12

  **Acceptance Criteria**:
  - [ ] flutter analyze passes
  - [ ] app build passes

- [ ] 14. Run full redesign QA pass

  **What to do**:
  - Validate the new feed-first experience end-to-end
  - Confirm home/feed/create/profile/settings flow is intuitive and demo-ready

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocked By**: 10,11,12

  **Acceptance Criteria**:
  - [ ] Home showcases friends’ content first
  - [ ] Create flow works for photo-only, voice-only, and both
  - [ ] Connections no longer dominate home

---

## Final Verification Wave

- [ ] F1. **Plan Compliance Audit** — `oracle`
- [ ] F2. **Code Quality Review** — `unspecified-high`
- [ ] F3. **Real Manual QA** — `unspecified-high`
- [ ] F4. **Scope Fidelity Check** — `deep`

---

## Commit Strategy

- IA + home redesign commit
- unified composer + navigation commit
- polish + verification commit

---

## Success Criteria

### Verification Commands
```bash
flutter analyze
flutter build apk --debug
```

### Final Checklist
- [ ] Friends’ shared feed is the main home experience
- [ ] Weekly check-in is compact on home
- [ ] Connections moved out of home prominence
- [ ] Single composer supports optional photo and/or voice
- [ ] Theme and visual polish are modernized
- [ ] Build/analyzer pass
