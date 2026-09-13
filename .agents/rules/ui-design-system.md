# UI Design System — MKX HRMS Mobile

## Card & List Style: Inset Grouped List (iOS Settings Style)

All card and list sections across the app MUST use the **Inset Grouped List** pattern.
This is implemented via the shared widgets in `lib/core/widgets/section_tile.dart`.

### Rules

1. **Never use a plain `Container` with `darkCard`/`lightCard` background + `darkBorder`/`lightBorder` border** to wrap content sections. This is the OLD pattern and must not be used.

2. **Use `SectionCard`** when rendering a list of similar items (e.g. info rows, payslip items, leave balances):
   ```dart
   SectionCard(
     isDark: isDark,
     children: [ /* plain widget children — no decoration needed */ ],
   )
   ```

3. **Use `SectionTile(position: TilePosition.only)`** for standalone single-item cards (e.g. profile header, latest disbursement card, theme preference card):
   ```dart
   SectionTile(
     isDark: isDark,
     position: TilePosition.only,
     padding: const EdgeInsets.all(20),
     child: /* content */,
   )
   ```

4. **Never nest `SectionTile` inside another `SectionTile`**. For inner sub-boxes within a tile (e.g. stat boxes), use a plain `Container` with:
   - `color: isDark ? AppColors.darkCard : AppColors.lightCard`
   - `border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)`
   - `borderRadius: BorderRadius.circular(10)`

5. **`TilePosition` values** (auto-handled by `SectionCard`, manual when using `SectionTile` directly):
   - `TilePosition.first` — top corners rounded (14px)
   - `TilePosition.middle` — no rounded corners
   - `TilePosition.last` — bottom corners rounded (14px)
   - `TilePosition.only` — all corners rounded (14px)

### Color Reference (DO NOT use raw hex — use AppColors tokens)
| Token | Dark | Light | Role |
|---|---|---|---|
| Tile background | `darkBorder` #191B1D | `lightBorder` #E4E4E7 | Tile fill |
| Tile border | `darkCard` #050607 | `lightCard` #FFFFFF | Separator / border |
| Sub-box background | `darkCard` #050607 | `lightCard` #FFFFFF | Nested box fill |
| Sub-box border | `darkBorder` #191B1D | `lightBorder` #E4E4E7 | Nested box border |
| Page background | `darkBackground` #020203 | `lightBackground` #FFFFFF | Scaffold bg |

### Applicable screens
Every screen that renders content cards, info rows, list items, or grouped settings
MUST follow this pattern. When editing or creating any screen, proactively apply
`SectionCard` / `SectionTile` instead of raw `Container` decorations.
