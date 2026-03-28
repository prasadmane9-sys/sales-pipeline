-- ================================================================
--  Humaine Labs — Sales Pipeline  (safe to re-run anytime)
-- ================================================================

-- 1. PROFILES TABLE
create table if not exists public.profiles (
  id         uuid references auth.users(id) on delete cascade primary key,
  full_name  text not null,
  role       text not null default 'member',
  created_at timestamptz default now()
);

-- 2. LEADS TABLE
create table if not exists public.leads (
  id         uuid default gen_random_uuid() primary key,
  contact    text not null,
  company    text default '',
  status     text not null default 'Warm',
  service    text default '',
  closure    text not null,
  revenue    integer default 0,
  owner      text not null,
  owner_id   uuid references auth.users(id) on delete set null,
  remarks    text default '',
  created_at timestamptz default now()
);

-- 3. ENABLE ROW LEVEL SECURITY
alter table public.profiles enable row level security;
alter table public.leads    enable row level security;

-- 4. ADMIN HELPER FUNCTION
create or replace function public.is_admin()
returns boolean
language sql security definer stable as $$
  select coalesce(
    (select role = 'admin' from public.profiles where id = auth.uid()),
    false
  );
$$;

-- 5. PROFILES POLICIES (drop first so re-run is safe)
drop policy if exists "Authenticated users can read profiles" on public.profiles;
drop policy if exists "Users insert own profile"              on public.profiles;
drop policy if exists "Users update own profile"              on public.profiles;

create policy "Authenticated users can read profiles"
  on public.profiles for select to authenticated using (true);

create policy "Users insert own profile"
  on public.profiles for insert to authenticated with check (auth.uid() = id);

create policy "Users update own profile"
  on public.profiles for update to authenticated using (auth.uid() = id);

-- 6. LEADS POLICIES (drop first so re-run is safe)
drop policy if exists "Members see own leads, admins see all" on public.leads;
drop policy if exists "Insert leads"                          on public.leads;
drop policy if exists "Update leads"                          on public.leads;
drop policy if exists "Delete leads"                          on public.leads;

create policy "Members see own leads, admins see all"
  on public.leads for select to authenticated
  using (owner_id = auth.uid() or public.is_admin());

create policy "Insert leads"
  on public.leads for insert to authenticated
  with check (owner_id = auth.uid() or public.is_admin());

create policy "Update leads"
  on public.leads for update to authenticated
  using (owner_id = auth.uid() or public.is_admin());

create policy "Delete leads"
  on public.leads for delete to authenticated
  using (owner_id = auth.uid() or public.is_admin());

-- ================================================================
--  DONE. Next steps:
--  1. Authentication > Settings > disable "Confirm email"
--  2. Copy your Project URL + anon key into index.html
-- ================================================================
