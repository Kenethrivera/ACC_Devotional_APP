---
name: Sanctuary Haven
colors:
  surface: '#f8f9ff'
  surface-dim: '#ccdbf1'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eef4ff'
  surface-container: '#e4efff'
  surface-container-high: '#daeaff'
  surface-container-highest: '#d4e4f9'
  on-surface: '#0d1d2c'
  on-surface-variant: '#424751'
  inverse-surface: '#233242'
  inverse-on-surface: '#e9f1ff'
  outline: '#727782'
  outline-variant: '#c2c6d3'
  surface-tint: '#155fab'
  primary: '#004482'
  on-primary: '#ffffff'
  primary-container: '#0f5ca8'
  on-primary-container: '#bdd5ff'
  inverse-primary: '#a6c8ff'
  secondary: '#2a6a48'
  on-secondary: '#ffffff'
  secondary-container: '#aceec4'
  on-secondary-container: '#2f6e4c'
  tertiary: '#493b74'
  on-tertiary: '#ffffff'
  tertiary-container: '#61528d'
  on-tertiary-container: '#dacdff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d5e3ff'
  primary-fixed-dim: '#a6c8ff'
  on-primary-fixed: '#001c3b'
  on-primary-fixed-variant: '#004787'
  secondary-fixed: '#aff1c6'
  secondary-fixed-dim: '#93d5ac'
  on-secondary-fixed: '#002111'
  on-secondary-fixed-variant: '#0a5132'
  tertiary-fixed: '#e8ddff'
  tertiary-fixed-dim: '#cebdff'
  on-tertiary-fixed: '#1f0f49'
  on-tertiary-fixed-variant: '#4c3d77'
  background: '#f8f9ff'
  on-background: '#0d1d2c'
  surface-variant: '#d4e4f9'
typography:
  display-hero:
    fontFamily: Newsreader
    fontSize: 3rem
    fontWeight: '500'
    lineHeight: 3.5rem
    letterSpacing: -0.02em
  display-hero-mobile:
    fontFamily: Newsreader
    fontSize: 2.25rem
    fontWeight: '500'
    lineHeight: 2.75rem
    letterSpacing: -0.015em
  headline-lg:
    fontFamily: Newsreader
    fontSize: 2rem
    fontWeight: '600'
    lineHeight: 2.5rem
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Newsreader
    fontSize: 1.625rem
    fontWeight: '600'
    lineHeight: 2.125rem
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Newsreader
    fontSize: 1.5rem
    fontWeight: '600'
    lineHeight: 2rem
  headline-sm:
    fontFamily: Newsreader
    fontSize: 1.25rem
    fontWeight: '600'
    lineHeight: 1.75rem
  body-reading:
    fontFamily: Plus Jakarta Sans
    fontSize: 1.0625rem
    fontWeight: '400'
    lineHeight: 1.75rem
    letterSpacing: 0.01em
  body-default:
    fontFamily: Plus Jakarta Sans
    fontSize: 0.9375rem
    fontWeight: '400'
    lineHeight: 1.5rem
  body-subtle:
    fontFamily: Plus Jakarta Sans
    fontSize: 0.875rem
    fontWeight: '400'
    lineHeight: 1.375rem
  label-caps:
    fontFamily: Plus Jakarta Sans
    fontSize: 0.6875rem
    fontWeight: '700'
    lineHeight: 1rem
    letterSpacing: 0.08em
  label-ui:
    fontFamily: Plus Jakarta Sans
    fontSize: 0.875rem
    fontWeight: '600'
    lineHeight: 1.25rem
  scripture-quote:
    fontFamily: Newsreader
    fontSize: 1.125rem
    fontWeight: '400'
    lineHeight: 1.875rem
    letterSpacing: 0.005em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1.25rem
  gutter-desktop: 1.75rem
  margin: 1rem
  margin-tablet: 2rem
  margin-desktop: 3rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-2xl: 3rem
---

## Brand & Style

This design system establishes a quiet, reverent digital sanctuary designed for meditative scripture reading, personal journaling, and intentional spiritual habits. Built around clarity, visual rest, and sacred dignity, it provides an oasis from high-stimulation interfaces.

### Core Philosophy & Personality
- **Contemplative & Serene:** Whitespace, warm mineral undertones, and generous line-heights evoke the physical tactility of open pages in a peaceful reading room.
- **Dignified & Literary:** Balanced pairings of classical literary serifs for contemplation alongside crisp modern sans-serifs for seamless interface navigation.
- **Trustworthy & Gracious:** Gentle pastel feedback surfaces, forgiving layouts, and soft transitions ensure habit tracking feels inspiring rather than penalizing.

### Aesthetic Movement
The aesthetic synthesizes modern **Warm Editorial Sanctuary** and **Tactile Neoclassicism**:
- Pill-shaped interaction targets and high card radiuses soften the viewport edges.
- Multi-tonal ambient surface washes (`#FBF9F5` warm cream, soft mist greens, subtle dawn lavenders, and morning-sky blues) replace harsh synthetic whites.
- Deep collegiate navy anchor accents create focused contrast that honors the word and church identity without visual aggression.

## Colors

The palette draws directly from early morning light filtered through sanctuary glass: deep oceanic blue, warm page parchment, eucalyptus sage, and dawn lavender.

### Palette Architecture
- **Primary (`#0F5CA8`):** The signature ACC deep blue. Anchors primary calls to action, brand identification markers, active day pill states, and the hero daily devotion container.
- **Primary Light Tint (`#E8F1FA`):** Used for subtle icon containers, active navigation pills, and interactive chip backgrounds.
- **Secondary Sage (`#3B7A57` / `#DCECE1`):** Represents spiritual growth, completed weekly milestones, and reflective progress. Free of alarming red or stark warning tones.
- **Tertiary Dawn Lavender (`#7A6BA8` / `#E9E4F5`):** Used for streak indicators, reflective journaling containers, and auxiliary progress states.
- **Warm Sand Accent (`#E89B66` / `#FBE6D6`):** Applied to reminder notes, notice banners, catch-up tasks, and gentle informational callouts.
- **Canvas & Surface System:** 
  - Canvas Root: `#FBF9F5` (warm ivory paper)
  - Card Surfaces: `#FFFFFF` with whisper borders (`rgba(19, 35, 56, 0.08)`)
  - Sub-elements & Recessed Wells: `#F5F2EB` and `#EDE9DF`

## Typography

The typographic hierarchy intentionally divides reading into two emotional registers:
1. **Sacred & Contemplative (Newsreader):** Carries the literary weight of devotional titles, scripture extracts, and modal greetings. Rendered in medium weights with generous line-height to reflect classic book typography.
2. **Utilitarian & Clarifying (Plus Jakarta Sans):** Carries interaction chrome, date badges, rhythm tracker day stamps, input text, and controls. Its subtle geometric warmth prevents modern UI from feeling cold or computerized.

### Layout Principles
- **Scripture Quotations:** Require an italicized variant of Newsreader with an indent spacing of `1.5rem` and muted border-left treatment in `#0F5CA8`.
- **Micro-Badges:** Category headers (`DAILY DEVOTION`, `PRIVATE REFLECTION`, `WEEKLY RHYTHM`) use `label-caps` in uppercase, tracked out by `0.08em` for refined editorial rhythm.

## Layout & Spacing

Layouts are designed to feel breathing, unhurried, and anchored. The design system prevents horizontal crowding by framing devotional content within maximum reading containers.

### Grid & Breakpoints
- **Mobile (< 768px):** Single-column vertical stream. 16px outer margins, card-to-card gap of `1.25rem`. Navigates through a floating bottom pill navigation bar.
- **Tablet (768px - 1024px):** 8-column layout. Split cards allowed for Devotion Hero and Streak metrics side-by-side. 32px outer canvas margins.
- **Desktop (1024px+):** Max-width canvas of `1240px` centered on viewport. 
  - Standard split-view layout: Left pane for scripture contemplation and hero overview; right pane for private reflection and active journaling toolbars.
  - Sticky header bar maintaining church diamond branding and back links.

### Spacing Tokens Usage
- Use `space-xs` (4px) and `space-sm` (8px) for badge inner padding, input prefix offsets, and pill chip margins.
- Use `space-md` (16px) for inner card partitions, inline toolbars, and weekly streak day targets.
- Use `space-lg` (24px) for primary card padding (`20px - 28px`), bottom sheet internal margins, and module gaps.
- Use `space-xl` (32px) and `space-2xl` (48px) for canvas section separation and hero illustration offsets.

## Elevation & Depth

Depth is treated as ethereal and ambient rather than layered or drop-shadow heavy. Elements seem to rest gracefully on paper stock rather than floating in 3D space.

### Depth Hierarchy
1. **Canvas (Base):** `#FBF9F5` flat textured surface with faint organic wave SVG vectors or photographic mountain-lake cross mist landscapes.
2. **Low-Elevation Cards (Resting):** Pure `#FFFFFF` fill supported by a dual-shadow formula:
   - Ambient: `0 4px 20px -2px rgba(15, 92, 168, 0.04)`
   - Structural: `0 1px 3px rgba(0, 0, 0, 0.03)`
   - Border: `1px solid rgba(19, 35, 56, 0.06)`
3. **Hero Container (Focal Point):** Deep `#0F5CA8` solid container, elevated by an inner white translucent gradient overlay (`rgba(255, 255, 255, 0.08)` to transparent) with a watermarked open-bible glyph at 15% opacity.
4. **Interactive Floating Elements (Active Overlays, Bottom Navigation, Modals):**
   - High diffuse shadow: `0 12px 32px -4px rgba(19, 35, 56, 0.12)`
   - Border: `1px solid rgba(255, 255, 255, 0.8)` for frosted overlays or `1px solid rgba(19, 35, 56, 0.08)`.

## Shapes

The shape system adopts a high roundedness scale (`roundedness: 3`) to foster warmth, gentleness, and comfort. Hard right angles are avoided across cards and interaction targets.

### Radius Assignments
- **Capsule / Pill (`9999px`):** Used universally for action buttons (`Open devotion`, `Add Version`, `Save Reflection`), week-tracker date day elements, category pill tags, and bottom navigation pill containers.
- **Cards & Reading Surfaces:** `1.5rem` (24px) on mobile viewports; scales gently to `1.25rem` (20px) on desktop interfaces for structural efficiency.
- **Modals & Bottom Sheets:** The top leading edges use `2rem` (32px) curvature paired with a centered pill drag handle (`40px × 4px`, radius `9999px`) in `#D0D7DE`.
- **Form Controls:** Text inputs feature an organic `0.875rem` (14px) curvature, preserving stability without feeling harsh.

## Components

### Buttons
- **Primary Action (Filled ACC Blue):** Height 48px, background `#0F5CA8`, text `#FFFFFF`, border-radius `9999px`, font `Plus Jakarta Sans` semi-bold (14px). Hover state shifts to `#0D4E8F` with subtle ambient bloom.
- **Hero White Action Pill:** Nested inside the blue devotion card; background `#FFFFFF`, text `#0F5CA8`, pill radius, icon trailing arrow (`→`).
- **Secondary Outlined Pill:** Background transparent, border `1px solid rgba(15, 92, 168, 0.3)`, text `#0F5CA8`. Hover state fills with `#E8F1FA`.
- **Ghost Action:** Text `#0F5CA8` or `#58697D`, padding `8px 12px`, no border.

### Today's Devotion Hero Card
- **Background:** Solid brand navy `#0F5CA8`.
- **Typography:** White serif display title (`Newsreader`), light subtitle, and scripture reference.
- **Accent Details:** Watermarked circular badge with an open scripture icon positioned top-right, translucent pill tag (`rgba(255, 255, 255, 0.2)` fill with crisp white caption).

### 7-Day Rhythm Tracker (Weekly Rhythm)
- **Container:** Pure `#FFFFFF` card or integrated surface module.
- **Pill Item Architecture:** A row of 7 tall capsule pills (`width: ~40px`, `height: ~58px`).
  - **Inactive Days:** Background `#FFFFFF` or `#FBF9F5`, border `1px solid rgba(19, 35, 56, 0.1)`, weekday label top, day number bottom in muted charcoal.
  - **Active Day (Today):** Background filled solid brand navy `#112338` or `#0F5CA8`, crisp white typography, gentle soft shadow.
  - **Completed Day:** Background tint in sage `#DCECE1`, typography in `#3B7A57`.

### Bible Passage & Warning Notice Cards
- **Passage Container:** `#FFFFFF` card with scripture header, reference badge, and "+ Add Version" pill button.
- **Translation Status Block:** Sub-container with recessed background `#F8FAFC`, subtle border `1px solid rgba(15, 92, 168, 0.08)`, book icon, book version note, and "Change" ghost button.
- **Notice / Warning Alert:** Warm sand background `#FBE6D6` or `#FDF4E7` with a 1px border (`#ECCAA0`), informational round icon `(i)`, and dark warm brown text for graceful non-blocking notices.

### Private Reflection Editor
- **Header:** Pill icon badge with pencil/reflection glyph, Newsreader title (`What is God showing you?`), and reassuring subtitle ("Optional and visible only to you").
- **Rich Text Toolbar:** Horizontal pill row featuring Undo, Redo, Size Selector, Bold, Italic, Underline, Color Palette, and Alignment icons. Micro-icon size 18px, interactive hover fill `#E8F1FA`.
- **Reflection Paragraph Block:** Reorderable card with drag handles (`⋮⋮`), up/down chevrons, close action (`✕`), and expandable textarea with placeholder: *"Write your private reflection..."*.
- **Footer Controls:** "+ Add Reflection Paragraph" dashed or outline pill button followed by full-width "Save Reflection" button.

### Bottom Navigation Bar (Mobile)
- **Container:** Dark navy pill container (`#11263C`) or frosted white floating pill elevated 16px above the device bottom edge.
- **Active State:** Contrasting rounded white pill background for the active tab icon, ensuring unambiguous focus.

### Modals & Bottom Sheets
- **Structure:** Up to 32px rounded top corners, background `#FBF9F5` or pure `#FFFFFF`.
- **Header:** Centered ACC diamond brand badge (`48px × 48px`, rounded 14px), serif greeting title (`Welcome Back`), and accessible dismiss cross icon at top right.