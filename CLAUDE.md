# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Kids-care-groceries is a centralized management platform for youth-in-care networks and multi-home foster organizations. It bridges administration and frontline operations:

- **Central administrators** oversee budgets, logistics, and multi-home reporting.
- **House staff** manage day-to-day grocery shopping, meal planning, and facility-level needs.

The platform is in early development — no code exists yet. This file should be updated as the tech stack and architecture are established.

## Domain Concepts

| Term | Meaning |
|------|---------|
| **Organization** | A foster-care network or agency managing multiple homes |
| **Home / Facility** | An individual group home or care site within an organization |
| **House Staff** | Frontline workers responsible for shopping and meal planning at a single home |
| **Central Admin** | Org-level administrator who sets budgets and monitors spending across homes |
| **Shopping List** | A facility-level list of items to purchase, linked to a budget period |
| **Meal Plan** | A planned set of meals for a home over a time window |
| **Budget** | An allocation of funds assigned by central admin to a home for a period |

## Key Design Constraints

- Role separation is critical: house staff must only see their own home's data; central admins see all homes.
- Budget limits must be enforced before purchases are approved, not after.
- The platform must remain usable by non-technical house staff (simple, mobile-friendly UI).
