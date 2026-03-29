# Draft: Sathi UI + Connectivity Redesign

## Requirements (confirmed)
- Remove or reduce the redundant "tiny homesick companion" intro/header treatment on home.
- Make the app UI feel more modern and polished.
- Improve the color theme.
- Show shared content from friends on the home screen instead of hiding it in the Connections tab.
- Reduce how much vertical space Connections and Weekly Check-in consume on home.
- Use more icon-driven modern navigation/actions.
- Allow taking/uploading a photo together with a voice note/journal in one combined flow instead of treating them as fully separate.
- Home should be feed-first.
- Connections should move into a profile/settings area.
- The create flow should be one composer where photo and voice are both optional attachments.

## Technical Decisions
- Planning only at this stage; no implementation yet.
- New home information hierarchy: feed-first.
- Connections will no longer occupy major home-screen real estate.
- Composer will unify the current separate photo and voice entry points.

## Research Findings
- Current app already has separate screens for Home, Record Voice, Upload Photo, Weekly Check-in, Insights, Share Summary, and Connections.
- Home currently uses large stacked action cards and a large intro card.
- Shared updates currently render inside Connections under "Shared with you".

## Open Questions
- Should Weekly Check-in stay on home as a compact chip/icon, or move behind a tab/secondary action?
- Should the home screen prioritize friends' shared content over personal wellbeing pulse, or keep both equally visible?

## Scope Boundaries
- INCLUDE: home redesign, navigation rethink, shared-content surfacing, compact action patterns, combined composer concept.
- EXCLUDE: implementation details until UX direction is clarified.
