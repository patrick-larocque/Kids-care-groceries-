# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Kids-care-groceries is a centralized management platform for youth-in-care networks and multi-home foster organizations. It bridges administration and frontline operations:

- **Central admins** (`central_admin` role) oversee budgets, approve shopping lists, and monitor all homes in their organization.
- **House staff** (`house_staff` role) manage day-to-day grocery shopping, meal planning, and facility-level needs from their mobile device.

## Tech Stack

| Layer | Choice |
|-------|--------|
| Monorepo | Turborepo + pnpm workspaces |
| Language | TypeScript (strict) |
| Mobile app | Expo (SDK 52) + Expo Router — house staff |
| Web admin | Next.js 15 (App Router) — central admins |
| Backend / DB | Supabase (PostgreSQL + Auth + RLS + Realtime) |
| Package manager | pnpm |

## Repository Structure

```
apps/
  mobile/          Expo app — house staff (shopping lists, meal plans)
  web/             Next.js app — admin dashboard (budgets, home management)
packages/
  db/              Supabase schema, migrations, and shared TypeScript types
    migrations/    SQL migration files (apply via Supabase CLI or dashboard)
    src/index.ts   Exports shared types; re-exports generated DB types after running generate-types
```

## Commands

```bash
# Install all dependencies (run from repo root)
pnpm install

# Run both apps in dev mode
pnpm dev

# Run a single app
pnpm --filter @kids-care/mobile dev   # Expo: opens QR code for Expo Go
pnpm --filter @kids-care/web dev      # Next.js: http://localhost:3000

# Type-check everything
pnpm type-check

# Lint everything
pnpm lint

# Regenerate Supabase TypeScript types (requires supabase CLI linked to project)
pnpm --filter @kids-care/db generate-types
```

## Supabase Setup

The project does not have a Supabase project yet. To set one up:

1. Create a project at https://supabase.com
2. Copy the project URL and anon key
3. Create `.env.local` in each app:
   ```
   # apps/web/.env.local and apps/mobile/.env.local
   NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
   NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
   ```
4. Apply the schema by running `packages/db/migrations/0001_initial_schema.sql` in the Supabase SQL editor
5. Run `pnpm --filter @kids-care/db generate-types` to pull TypeScript types from the live schema

## Domain Model

```
Organization
└── Home (many)
    ├── Profile/User (house_staff — scoped to this home)
    ├── Budget (set by central_admin per time period)
    ├── ShoppingList → ShoppingListItems (created by house_staff)
    └── MealPlan → MealPlanEntries (weekly, one per home per week)

Organization
└── Profile/User (central_admin — sees all homes)
```

## Key Architectural Decisions

**Role separation via Supabase RLS** — Data access is enforced at the database level using Row Level Security policies in `0001_initial_schema.sql`, not in application code. `house_staff` can only read/write rows belonging to their `home_id`. `central_admin` can read all rows in their `organization_id`. Never bypass RLS by using the service role key on the client.

**Budget enforcement before purchase** — Budget limits must be checked before a shopping list is approved, not reconciled after. The `status` column on `shopping_lists` (`draft → submitted → approved → purchased`) is the gate; only `central_admin` can set status to `approved`.

**Shared types via `@kids-care/db`** — Both apps import domain types from `packages/db`. After any schema change, run `generate-types` and commit the updated `database.types.ts`.

**Monorepo filter pattern** — Turborepo caches builds per package. When adding dependencies, always use `pnpm --filter @kids-care/<app> add <package>` rather than installing at the root.

## Domain Glossary

| Term | Meaning |
|------|---------|
| Organization | A foster-care network or agency managing multiple homes |
| Home / Facility | An individual group home or care site |
| House Staff | Frontline workers at a single home; mobile app users |
| Central Admin | Org-level administrator; web dashboard users |
| Shopping List | A facility-level list of items to purchase, linked to a budget |
| Meal Plan | Planned meals for a home over one week |
| Budget | A spending allocation set by central admin for a home and time period |
