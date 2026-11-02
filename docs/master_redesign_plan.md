# Balaji Points Master Redesign Plan

## 1. Design foundation from the reviewed references

The Carpenter Rewards UI PDF and bundled HTML are the visual source of truth. The architecture PDF supplies the role/permission and platform requirements. When the visual references and this older plan disagree, follow the rendered UI references and keep the architecture’s security boundaries.

- Product is a multi-tenant, multi-branch, multi-role rewards platform.
- Core visual language is deep navy navigation/hero surfaces, warm off-white page canvas, white rounded cards, Inter typography, restrained gold accents, and coral primary actions on a Material 3 foundation.
- Registration and first-time onboarding should feel premium and conversion-friendly.
- The app must work across mobile, tablet, and web without redesigning the experience from scratch.
- Role separation is essential: carpenter, branch admin, and super admin each need distinct dashboards and permissions.

Key reference signals:

- PDF mobile flow: create account, sign in, points dashboard, bill detail, profile, wallet, and rewards use large touch targets, rounded white surfaces, navy headers/points cards, coral CTAs, and explicit pending approval states.
- HTML desktop flow: a persistent navy left navigation rail with an active gold marker, a neutral canvas, compact operational cards, and data tables for branch admin and super admin.
- Architecture brief: Flutter Material 3, light/dark themes, responsive mobile/tablet/desktop/web, explicit branch membership, and permission-scoped roles.
- Visual parity means preserving the same hierarchy, colors, spacing, labels, and interaction patterns while adapting layout for available width—not stretching a phone screenshot across desktop.

---

## 2. Product direction

Balaji Points should be redesigned as a modern rewards-management platform for trade businesses, not just a single app screen set. The redesign should feel like:

- Trustworthy and premium
- Fast for daily operations
- Clear for branch staff and carpenters
- Scalable for more branches and future admin roles

The visual language should stay simple, confident, and operational: clean surfaces, generous spacing, strong contrast, and a reliable system of cards, filters, and status chips.

---

## 3. Role-based product architecture

### 3.1 Carpenter role

Primary objective: submit bills, track points, view rewards, and understand status.

#### Core screens
- Register / welcome
- Login / email and password / Google sign-in / password reset
- Dashboard
- My bills
- Add bill
- Wallet / points summary
- Offers and redemptions
- Notifications
- Profile and settings

#### UX goals
- Simple, low-friction onboarding
- Urgent visibility of “pending approval” states
- Clear point growth and reward status
- Responsive experience with quick access to bill submission

#### Key UI patterns
- Hero summary cards for total points, eligible amount, and status
- Large CTA for “Add new bill”
- Meters or progress bars for rewards/targets
- Recent transactions list with status chips

### 3.2 Branch admin role

Primary objective: manage carpenters, approve bills, maintain branch operations, and review branch health.

#### Core screens
- Admin dashboard
- Pending bill approvals
- Carpenter roster
- Branch overview and metrics
- Reports and payout summary
- Branch settings
- Notifications
- Duplicate account / audit tools

#### UX goals
- High-speed approval workflow
- Strong visibility into branch performance
- Low cognitive load for operational tasks
- Ability to review, approve, reject, and communicate clearly

#### Key UI patterns
- Approval queue with filter chips and search
- Summary KPI cards for bills, approvals, carpenters, and pending tasks
- Tables on tablet/desktop; stacked cards on mobile
- Branch status banners and alerts

### 3.3 Super admin role

Primary objective: control business-wide health, branches, operators, and platform-level functions.

#### Core screens
- Super admin dashboard
- Branch overview by region / business
- Branch creation and management
- Admin assignment by branch
- User health and duplicate-account checks
- Audit logs and backups
- Reporting and platform controls

#### UX goals
- Global visibility without noisy clutter
- Fast scanning of branch health
- Clear ownership and assignment model
- Secure, low-risk operational actions

#### Key UI patterns
- Executive dashboard with KPIs and branch cards
- Side navigation on desktop/tablet
- Top-level filters by tenant/branch/status
- High-contrast action panels for create, assign, and archive flows

### 3.4 Future/secondary roles

The architecture document suggests a broader role model beyond the current app:

- Manager
- Accountant
- Supervisor
- Tenant admin

These should be designed as permission-driven, not hardcoded. The UI system should support role-based visibility by capability rather than by a few static screens.

---

## 4. Recommended design system

### 4.1 Visual identity

Use the existing strong direction:

- Primary: deep navy
- Accent: warm gold
- Support: white / soft gray surfaces
- Status colors: success green, warning amber, error red

This palette matches the clean premium aesthetic of the reference UI and supports trust in a business ops app.

### 4.2 UI language

- Rounded corners for cards and inputs
- Strong section headers
- Solid surface cards with soft borders
- Clear chips and status pills
- Large CTA buttons with strong contrast
- Material 3 components with consistent elevation and spacing

### 4.3 Typography

Use a clean modern sans family with a scale that supports:

- H1/H2 for major headings
- H3/H4 for section headings
- Body / labels for forms and lists
- Small text for metadata and chips

### 4.4 Spacing system

Use an 8px-based spacing system:

- xs: 4
- sm: 8
- md: 12 / 16
- lg: 20 / 24
- xl: 32
- xxl: 40+

This should be applied consistently to cards, lists, form groups, and sections.

---

## 5. Responsive system

### 5.1 Mobile

Target: phones from small to large screens.

#### Mobile patterns
- Single-column layouts
- Stacked cards and transaction rows
- Bottom navigation or compact tab bar when appropriate
- Large form fields for one-handed input
- Full-width CTA buttons

#### Mobile UX rules
- Keep important actions within the first screen fold
- Use sticky summary bars when needed
- Reduce nested navigation depth for task completion

### 5.2 Tablet

Target: 768px–1199px screen widths.

#### Tablet patterns
- Two-column layout for dashboard summaries
- Split view for list + detail panels
- Side filters with result list
- More comfortable data tables with moderate density

#### Tablet UX rules
- Keep critical workflows within a single content cluster
- Use column layouts for branch summary and action queue

### 5.3 Web / desktop

Target: 1200px+ screens.

#### Web patterns
- Fixed left navigation or top nav with dashboard shells
- Multi-panel layouts for approval and reporting
- Data tables with sortable columns
- Executive overview cards and branch-level detail panes

#### Web UX rules
- Reduce visual clutter; emphasize scanability
- Use denser information without sacrificing readability
- Keep cross-role actions clearly separated by permissions

---

## 6. Navigation model

### 6.1 Shared shell

Create a shared shell for all roles:

- top bar with app identity, search, notifications, and profile
- left navigation on larger screens
- bottom nav for mobile for the most common tasks
- contextual action bar for screen-specific actions

### 6.2 Role-based shells

- Carpenter shell: Home, Bills, Wallet, Offers, Notifications, Profile
- Admin shell: Dashboard, Approvals, Carpenters, Reports, Branch Settings, Notifications
- Super admin shell: Overview, Branches, Admins, Users, Audits, Settings

The routing should stay permission-driven, not just role-based by string checks.

---

## 7. Detailed screen redesign priorities

### Phase 1: foundation and conversion
1. Registration / onboarding screen
2. Login / PIN flow
3. Carpenter dashboard
4. Add bill flow
5. Wallet / points summary

### Phase 2: operations and admin workflows
1. Admin approvals dashboard
2. Branch admin roster management
3. Bill review and status actions
4. Reports and summaries

### Phase 3: platform and governance
1. Super admin overview
2. Branch management
3. Admin assignment and access protection
4. Backup/audit screens
5. Multi-branch reporting

---

## 8. UX principles for the redesign

- Keep tasks close to the user’s daily workflow.
- Prioritize clarity over decoration.
- Use status colors consistently but sparingly.
- Default to strong hierarchy and readable spacing.
- Separate operational actions from informational content.
- Build each role around a single primary task: carpenter = earn + submit; admin = approve + manage; super admin = monitor + govern.

---

## 9. Implementation strategy

### 9.1 Frontend structure

Build a reusable design system layer in Flutter with:

- color tokens
- typography tokens
- spacing scale
- card variants
- button variants
- input styles
- status chips
- empty-state patterns
- dashboard widgets

### 9.2 Shared widgets

Create a reusable widget library for:

- App shell layout
- Header + search bar
- KPI cards
- Filter pills
- Section headers
- Empty states
- Data tables
- Transaction rows
- Drawer / nav menu

### 9.3 Per-role screen groups

Use role-specific modules while keeping a common underlying shell and design foundation.

---

## 10. Acceptance criteria

The redesign will be considered successful when:

- Every role has a clear primary dashboard and task path.
- The same information architecture works across mobile, tablet, and web.
- Registration and login feel premium and trustworthy.
- Branch admin and super admin can operate effectively with reduced clutter.
- Carpenter users can complete daily tasks in under a few taps.
- The app remains visually consistent with the approved Navy + Gold brand direction.

---

## 11. Recommended next step

The immediate next step should be:

1. Finalize the UX architecture for carpenter, admin, and super admin.
2. Convert the visual identity into reusable Flutter theme tokens.
3. Rebuild the app shell and navigation per role.
4. Then implement each dashboard in a role-by-role mobile-first sequence before scaling to tablet and web layouts.

This approach reduces risk while keeping the redesign aligned with the architecture blueprint and the approved visual direction.
