-- Organizations: top-level foster-care networks / agencies
create table organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz default now()
);

-- Homes: individual group-home facilities within an organization
create table homes (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  name text not null,
  address text,
  created_at timestamptz default now()
);

-- Profiles: extends auth.users with role and org/home assignment
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  organization_id uuid not null references organizations(id),
  home_id uuid references homes(id),   -- null for central_admin
  role text not null check (role in ('central_admin', 'house_staff')),
  full_name text,
  created_at timestamptz default now()
);

-- Budgets: a spending allocation set by central_admin for a home over a period
create table budgets (
  id uuid primary key default gen_random_uuid(),
  home_id uuid not null references homes(id) on delete cascade,
  period_start date not null,
  period_end date not null,
  amount_cents integer not null check (amount_cents >= 0),
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- Shopping lists: created by house_staff, linked to a budget
create table shopping_lists (
  id uuid primary key default gen_random_uuid(),
  home_id uuid not null references homes(id) on delete cascade,
  budget_id uuid references budgets(id),
  name text not null,
  status text not null default 'draft'
    check (status in ('draft', 'submitted', 'approved', 'purchased')),
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- Shopping list items
create table shopping_list_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references shopping_lists(id) on delete cascade,
  name text not null,
  quantity integer not null default 1 check (quantity > 0),
  unit text,
  estimated_cost_cents integer check (estimated_cost_cents >= 0),
  actual_cost_cents integer check (actual_cost_cents >= 0),
  purchased boolean not null default false,
  created_at timestamptz default now()
);

-- Meal plans: weekly plans created by house_staff for a home
create table meal_plans (
  id uuid primary key default gen_random_uuid(),
  home_id uuid not null references homes(id) on delete cascade,
  week_start date not null,
  created_by uuid references profiles(id),
  created_at timestamptz default now(),
  unique (home_id, week_start)
);

-- Meal plan entries: individual meals within a plan
create table meal_plan_entries (
  id uuid primary key default gen_random_uuid(),
  meal_plan_id uuid not null references meal_plans(id) on delete cascade,
  day_of_week integer not null check (day_of_week between 0 and 6),
  meal_type text not null check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
  description text not null,
  created_at timestamptz default now()
);

-- ============================================================
-- Row Level Security
-- ============================================================

alter table organizations enable row level security;
alter table homes enable row level security;
alter table profiles enable row level security;
alter table budgets enable row level security;
alter table shopping_lists enable row level security;
alter table shopping_list_items enable row level security;
alter table meal_plans enable row level security;
alter table meal_plan_entries enable row level security;

-- Helper: returns the profile row for the current user
create or replace function current_profile()
returns profiles language sql security definer stable as $$
  select * from profiles where id = auth.uid()
$$;

-- Organizations: members of the org can read it
create policy "org members can read their org"
  on organizations for select
  using (id = (current_profile()).organization_id);

-- Homes: central_admin sees all homes in org; house_staff sees only their home
create policy "central_admin sees all homes in org"
  on homes for select
  using (
    organization_id = (current_profile()).organization_id
    and (current_profile()).role = 'central_admin'
  );

create policy "house_staff sees own home"
  on homes for select
  using (id = (current_profile()).home_id);

-- Budgets: central_admin can read/write; house_staff can read their home's budgets
create policy "central_admin manages budgets"
  on budgets for all
  using ((current_profile()).role = 'central_admin'
    and home_id in (select id from homes where organization_id = (current_profile()).organization_id));

create policy "house_staff reads own budget"
  on budgets for select
  using (home_id = (current_profile()).home_id);

-- Shopping lists: house_staff manages their home; central_admin can read all in org
create policy "house_staff manages own lists"
  on shopping_lists for all
  using (home_id = (current_profile()).home_id);

create policy "central_admin reads all lists in org"
  on shopping_lists for select
  using (
    (current_profile()).role = 'central_admin'
    and home_id in (select id from homes where organization_id = (current_profile()).organization_id)
  );

-- Shopping list items: inherit access from the parent list's home
create policy "access items via list home"
  on shopping_list_items for all
  using (
    list_id in (
      select id from shopping_lists where home_id = (current_profile()).home_id
    )
  );

-- Meal plans: house_staff manages their home; central_admin reads all in org
create policy "house_staff manages own meal plans"
  on meal_plans for all
  using (home_id = (current_profile()).home_id);

create policy "central_admin reads all meal plans in org"
  on meal_plans for select
  using (
    (current_profile()).role = 'central_admin'
    and home_id in (select id from homes where organization_id = (current_profile()).organization_id)
  );

create policy "access meal plan entries via home"
  on meal_plan_entries for all
  using (
    meal_plan_id in (
      select id from meal_plans where home_id = (current_profile()).home_id
    )
  );

-- Profiles: users can read their own profile; central_admin reads all in org
create policy "users read own profile"
  on profiles for select
  using (id = auth.uid());

create policy "central_admin reads profiles in org"
  on profiles for select
  using (
    (current_profile()).role = 'central_admin'
    and organization_id = (current_profile()).organization_id
  );
