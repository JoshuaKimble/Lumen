# Journal App Product Requirements Context Dump

## Product Vision

Build a voice-first journaling app that helps users quickly capture raw
thoughts, then uses AI to summarize those thoughts, surface recurring themes,
and turn them into helpful gospel-focused study guides.

The app should preserve the user's original words while also adding lightweight
AI metadata that makes entries easier to revisit and reflect on later.

The core value is not just "journaling," but helping users discover patterns,
themes, emotional threads, and meaningful connections across their entries over
time.

---

## Core Product Concept

Users should be able to:

1. Open the app and quickly record a journal entry by voice.
2. Optionally type instead of recording.
3. Save the original raw entry.
4. Generate an AI summary and optional title for easier recall.
5. Detect high-level themes from the entry.
6. Browse recurring themes over time.
7. Open a study guide generated from a journal entry.
8. Later, tap a theme to see related journal entries and future theme-level
   study guidance.

---

## Primary User Experience

The app should feel lightweight and frictionless.

The ideal flow is:

1. User has a thought, experience, reflection, or emotional moment.
2. User opens the app.
3. User records or types the entry.
4. App saves the original entry.
5. AI produces a lightweight summary.
6. App tags the entry with themes.
7. App generates a study guide from the reflection.
8. User can later review entries by date, theme, or continue study from the
   generated guide.

The app should help users journal even when their thoughts are messy,
fragmented, emotional, or stream-of-consciousness.

---

## Entry Creation Requirements

### Voice-First Entry

The main entry method should be voice recording.

Users should be able to:

- Start a voice entry quickly.
- Stop recording when finished.
- Review the transcribed text.
- Save the entry.
- Generate summary, themes, and a study guide from the transcript.

The app should make voice capture feel like the default path, not a secondary
feature.

### Text Entry

Users should also be able to create entries by typing.

Users should be able to:

- Start a text journal entry.
- Write freely.
- Save the original text.
- Generate summary, themes, and a study guide.
- Edit before or after saving if needed.

---

## Original Entry Requirements

Each journal entry should preserve the original version:

### Original Entry

The original entry is the user's raw transcription or typed input.

This should be saved as-is, aside from basic transcription cleanup if needed.

The original matters because it preserves the user's authentic voice, emotion,
and wording.

## Summary Requirements

The summary should be AI-generated metadata rather than a replacement for the
entry itself.

It should:

- Keep the meaning of the original.
- Preserve the user's perspective.
- Improve recall without rewriting the whole entry.
- Avoid sounding overly polished, fake, clinical, or generic.
- Avoid changing the substance of the user's thoughts.
- Avoid adding conclusions the user did not express.

---

## Theme Detection Requirements

The app should identify high-level themes from journal entries.

Examples of themes could include:

- Family
- Work
- Stress
- Faith
- Gratitude
- Parenting
- Anxiety
- Goals
- Health
- Relationships
- Personal growth
- Conflict
- Decision-making

Themes should help the user see patterns across their entries.

The app should not overwhelm the user with too many tags. It should favor
meaningful, recurring, high-level themes over overly specific labels.

---

## Word Cloud / Theme Visualization

The app should include a visual way to show recurring themes.

A word cloud is the current preferred concept.

The word cloud should:

- Surface themes that appear across entries.
- Make more frequent or more significant themes visually prominent.
- Let users quickly see what topics are showing up in their life.
- Allow users to tap a theme to explore it.

This should feel reflective, not gamified or noisy.

---

## Theme Detail Experience

When a user taps a theme, they should see a detail view for that theme.

The theme detail view should include:

- Journal entries associated with that theme.
- Related AI-generated insights or summaries.
- Future theme-level study guidance.

The purpose is to let users explore recurring patterns in their life, not just
see a static tag list.

---

## Study Guide Requirements

The study guide is the primary generated outcome of a journal entry.

The journal entry is the input. The study guide is the path forward.

In V1, study guides are entry-based only. Theme-based guides are deferred.

Study guide content may include:

- Articles
- Videos
- Scriptures
- Quotes
- Reflection prompts
- Exercises
- Other user-created entries

The guide should organize these resources into a concise, trustworthy study
experience rather than exposing them as a flat list.

The guide should feel helpful and reflective, not like random
recommendations or homework.

---

## Study Guide and Reflection Prompt Policy (Planned)

This section defines the intended product behavior for Study Guides and
reflection prompts so implementation can be scoped safely.

### Resource Types

The app should support these study-guide resource types:

- `reflection_prompt`: short journaling prompts that help the user reflect
  further.
- `scripture`: canonical scripture references and links.
- `talk_or_article`: conference talks, devotionals, or long-form articles.
- `video_or_audio`: podcast, talk, or video media.
- `quote`: short supporting quotes.
- `exercise`: small guided practice (for example: breathing, gratitude, or
  reframing).
- `internal_entry_link`: links to prior user entries related to the same theme.

### Source Strategy

Initial strategy should be mixed:

1. Curated catalog for trusted baseline quality.
2. AI-generated guide construction that maps entry context to curated items.
3. User-created links or notes as an optional later enhancement.

The product should avoid fully open-ended recommendations in MVP stages.

### Helpfulness Policy

The system should prioritize relevance, emotional safety, and study value:

- Study guide resources must connect to the current entry text or detected
  themes.
- The guide should stay high-level and avoid overconfident life advice.
- If confidence is low, show fewer resources rather than noisy suggestions.
- Resources should never be presented as diagnosis, treatment, or authority.
- The app should be explicit that the guide is supportive and user-controlled.

### Association Rules

Association should happen at two levels:

1. Entry-level guides: generated from the entry text and detected themes.
2. Theme-level guides: generated from recurring themes and reused across
   entries in that theme in a later version.

Each generated resource should include provenance metadata:

- source type (`curated`, `ai_mapped`, future `user_created`)
- match reason (theme match, keyword match, intent match)
- confidence score
- optional `entryId` and/or `themeId`

### Reflection Prompt Behavior

Reflection prompts should be:

- brief and open-ended
- non-judgmental
- focused on clarifying user thoughts, not directing outcomes

In V1, every study guide should include one required reflection prompt.

Prompt generation should favor prompt templates + theme adaptation over fully
free-form generation in early versions.

### User Controls

Users should be able to:

- open study resources in their preferred study app
- manually mark resources complete
- revisit a guide later without losing completion state
- save a suggestion
- mark suggestions as not helpful
- select preferred resource traditions/providers in settings (planned)

These controls should influence future ranking.

---

## Journal Entry Data Requirements

Each journal entry should conceptually include:

- Entry ID
- Created date/time
- Original text
- Rewritten text
- Associated themes
- Associated links/resources
- Entry type/source, such as voice or text
- Optional title or generated summary
- Optional user edits

The most important product requirement is that the app keeps the original and
rewritten text together as part of the same entry.

---

## Entry List Requirements

Users should be able to view previous entries.

The entry list should likely show:

- Date
- Optional title or short summary
- A preview of the rewritten entry or original entry
- Associated themes

Users should be able to open an entry and view both the original and rewritten
versions.

---

## Entry Detail Requirements

The entry detail screen should include:

- Original entry text
- Rewritten entry text
- Themes
- Related resources or links
- Created date/time
- Any generated summary or title, if available

The user should be able to distinguish clearly between the original and
rewritten version.

---

## AI Behavior Requirements

AI should act as a reflective writing assistant, not a therapist, preacher,
coach, or judge.

AI should:

- Clarify the user's writing.
- Preserve the user's meaning.
- Identify themes.
- Help surface patterns.
- Suggest useful resources or reflection prompts when appropriate.

AI should not:

- Diagnose the user.
- Overstate emotional conclusions.
- Add details that were not present.
- Make the entry sound unlike the user.
- Turn every entry into advice.
- Treat normal emotions as problems to solve.

---

## Product Consideration: Sensitive Journaling vs Thought Exploration

The product team needs to carefully explore an unresolved UX and product
distinction between:

1. Thought exploration / idea development.
2. Personal journaling / emotional processing.

The current product direction is to treat automatic summary, themes, and
Study Guide generation as the default journaling assistance. Users may still dump
raw thoughts about subjects like theology, scripture study, philosophy,
creative ideas, or personal frameworks, but the app should not assume that a
full rewrite is the right default response. In these cases, lighter AI support
is broadly valuable because it can:

- Improve recall without replacing the original text.
- Help users reflect on and internalize their own ideas.
- Surface themes worth exploring further.

However, this interaction model may not translate well to emotionally sensitive
or deeply personal journaling.

Examples of sensitive journaling contexts include:

- Marriage struggles.
- Parenting frustrations.
- Depression or anxiety.
- Job stress.
- Trauma or grief.
- Highly vulnerable emotional processing.

In these cases, an automatic AI rewrite could potentially:

- Feel emotionally distancing.
- Over-formalize vulnerable thoughts.
- Remove emotional authenticity.
- Make the entry feel less personal or human.
- Create discomfort around exposing sensitive information to AI processing.

The current product decision is that rewrite-first should not be the default
core journaling experience across both thought exploration and sensitive
personal journaling.

Open product questions:

- When is rewriting genuinely valuable?
- What should a future explicit editor flow look like for idea exploration and
  note organization?
- Should users choose between "journal mode" and "idea exploration mode"?
- How should user trust and emotional safety influence the UX?
- How do we communicate privacy and AI-processing expectations clearly?

Future product decisions should account for emotional sensitivity, trust, and
the fact that users may bring different journaling intents into the same app.

---

## Tone and Feel

The app should feel:

- Calm
- Private
- Thoughtful
- Reflective
- Simple
- Trustworthy
- Emotionally safe

It should not feel:

- Busy
- Social-media-like
- Overly clinical
- Overly gamified
- Overly productivity-focused
- Like a chatbot app with journaling attached

---

## Privacy and Trust Product Requirements

Because this is a journal app, users need to trust it.

The product should make it clear that:

- Entries are private.
- Original entries are preserved.
- AI-generated rewrites are suggestions, not replacements.
- The user owns their thoughts and can edit or delete entries.

Important user actions should include:

- Delete an entry.
- Edit an entry.
- Regenerate a rewritten version.
- View the original version at any time.

---

## MVP Scope

The MVP should focus on the core journaling loop.

### MVP Must-Haves

- Create a journal entry by voice.
- Create a journal entry by text.
- Save original entry text.
- Generate rewritten entry text.
- Display both original and rewritten versions.
- Detect and save themes.
- Show a list of past entries.
- Show entry detail.
- Show a basic theme/word cloud view.
- Tap a theme to view related entries.

### MVP Nice-to-Haves

- Generated entry titles.
- Generated short summaries.
- Related links/resources.
- Regenerate rewrite.
- Edit rewritten version.
- Search entries.
- Filter entries by theme.
- Reflection prompts.

---

## Future Product Ideas

Possible future features:

- Daily or weekly reflection summaries.
- Mood or emotional trend tracking.
- More advanced theme clustering.
- Scripture or quote recommendations.
- Guided journaling prompts.
- Reminder notifications.
- Export entries.
- Private collections or folders.
- Timeline view.
- "What have I been thinking about lately?" AI summary.
- "Show me entries where I talked about family/work/faith/etc."
- Conversational search across journal history.

---

## Product Priorities

The product should prioritize:

1. Fast capture.
2. Preserving the original entry.
3. Helpful AI rewriting.
4. Meaningful theme detection.
5. Easy review over time.
6. Trust and privacy.

The app should avoid adding too many features before the core journaling
experience feels excellent.

---

## Non-Goals for Initial Product

For the initial version, the app should not try to be:

- A full therapy app.
- A social journaling network.
- A generic notes app.
- A task manager.
- A habit tracker.
- A full AI chatbot experience.
- A productivity dashboard.

The product should stay centered on reflective journaling.

---

## One-Sentence Product Summary

A voice-first AI journal that captures raw thoughts, preserves the original
entry, rewrites it into a clearer reflection, and helps users discover recurring
themes across their life over time.
