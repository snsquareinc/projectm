-- Phase 1 database: library, projects, budget lines, vendors, insurance, payments, receipts.
-- Run once in Supabase: SQL Editor > New query > paste > Run.
-- Safe to re-run: uses "if not exists" and "on conflict do nothing".
-- Old tables from the first version (project, categories, tasks, receipts) are left alone.

-- ============================================================
-- LIBRARY (global, shared by every project)
-- ============================================================

create table if not exists library_divisions (
  code text primary key,                 -- e.g. '080-000'
  name text not null,
  bank_funded boolean not null default true,
  sort_order int not null default 0,
  retired boolean not null default false
);

create table if not exists library_subtasks (
  code text primary key,                 -- e.g. '080-010'
  division_code text not null references library_divisions(code),
  name text not null,
  sort_order int not null default 0,
  retired boolean not null default false
);

-- ============================================================
-- PROJECTS AND BUDGET
-- ============================================================

create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text not null default '',
  status text not null default 'Planning',   -- Planning, Active, Sold
  lender text not null default '',
  loan_amount numeric not null default 0,
  general_contractor text not null default '',
  start_date date,
  end_date date,
  created_at timestamptz not null default now()
);

-- One row per budget line on a project. A line is either a sub-task from the
-- library (subtask_code set) or a free-form line (subtask_code null).
-- Division totals are sums of these lines, so the bank report always matches.
create table if not exists project_lines (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  division_code text not null references library_divisions(code),
  subtask_code text references library_subtasks(code),
  label text not null default '',
  budget numeric not null default 0,
  revision numeric not null default 0,          -- approved changes after locking
  revision_reason text not null default '',
  bank_funded boolean not null default true,
  created_at timestamptz not null default now()
);

-- ============================================================
-- VENDORS, INSURANCE, TAX FORMS
-- ============================================================

create table if not exists vendors (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  company text not null default '',
  phone text not null default '',
  email text not null default '',
  trade text not null default '',
  is_corporation boolean not null default false,  -- excluded from 1099 totals
  w9_path text,                                    -- file in the 'receipts' bucket
  created_at timestamptz not null default now()
);

-- Insurance certificate for a vendor on a specific project.
-- A vendor on a project with no row here shows "COI required".
create table if not exists vendor_insurance (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid not null references vendors(id) on delete cascade,
  project_id uuid not null references projects(id) on delete cascade,
  insurer text not null default '',
  policy_number text not null default '',
  expires_on date,
  holder_listed boolean not null default false,    -- bank named as certificate holder
  file_path text,                                   -- the COI file in the 'receipts' bucket
  dismissed_reason text,                            -- set when you hide the reminder
  dismissed_by text,
  dismissed_at timestamptz,
  created_at timestamptz not null default now()
);

-- ============================================================
-- PAYMENTS AND RECEIPTS
-- ============================================================

-- Every payment must have a budget line. Nothing is saved unclassified.
create table if not exists payments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  vendor_id uuid references vendors(id),
  budget_line_id uuid not null references project_lines(id),
  pay_date date not null,
  amount numeric not null,
  method text not null default 'Check',            -- Check, ACH, Wire, Cash
  reference text not null default '',              -- check or reference number
  invoice_number text not null default '',
  status text not null default 'Waiting on vendor',  -- Waiting on vendor, Confirmed, Disputed
  confirmed_name text,
  confirmed_at timestamptz,
  draw_number int,                                 -- set when the payment goes into a draw
  created_at timestamptz not null default now()
);

create table if not exists payment_receipts (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references payments(id) on delete cascade,
  path text not null,                              -- file in the 'receipts' bucket
  filename text not null default '',
  created_at timestamptz not null default now()
);

-- ============================================================
-- ACCESS RULES: signed-in users only
-- ============================================================

alter table library_divisions enable row level security;
alter table library_subtasks enable row level security;
alter table projects enable row level security;
alter table project_lines enable row level security;
alter table vendors enable row level security;
alter table vendor_insurance enable row level security;
alter table payments enable row level security;
alter table payment_receipts enable row level security;

drop policy if exists "signed-in full access" on library_divisions;
drop policy if exists "signed-in full access" on library_subtasks;
drop policy if exists "signed-in full access" on projects;
drop policy if exists "signed-in full access" on project_lines;
drop policy if exists "signed-in full access" on vendors;
drop policy if exists "signed-in full access" on vendor_insurance;
drop policy if exists "signed-in full access" on payments;
drop policy if exists "signed-in full access" on payment_receipts;

create policy "signed-in full access" on library_divisions for all to authenticated using (true) with check (true);
create policy "signed-in full access" on library_subtasks for all to authenticated using (true) with check (true);
create policy "signed-in full access" on projects for all to authenticated using (true) with check (true);
create policy "signed-in full access" on project_lines for all to authenticated using (true) with check (true);
create policy "signed-in full access" on vendors for all to authenticated using (true) with check (true);
create policy "signed-in full access" on vendor_insurance for all to authenticated using (true) with check (true);
create policy "signed-in full access" on payments for all to authenticated using (true) with check (true);
create policy "signed-in full access" on payment_receipts for all to authenticated using (true) with check (true);

-- Receipts, insurance certificates and W-9s live in the existing private 'receipts' bucket.
-- (Created by schema.sql in the first setup. Created again here in case it is missing.)
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', false)
on conflict (id) do nothing;

drop policy if exists "signed-in receipts access" on storage.objects;
create policy "signed-in receipts access" on storage.objects for all to authenticated
  using (bucket_id = 'receipts') with check (bucket_id = 'receipts');

-- ============================================================
-- LIBRARY SEED: 21 divisions, 212 sub-tasks (duplicates removed)
-- ============================================================

insert into library_divisions (code, name, sort_order) values
('010-000','General requirements',1),
('020-000','Site prep',2),
('030-000','On-site water and sewer',3),
('040-000','Utilities',4),
('050-000','Excavation and earthwork',5),
('060-000','Foundation',6),
('070-000','Other masonry and paving',7),
('080-000','Rough framing',8),
('090-000','Roofing',9),
('100-000','Exterior',10),
('110-000','Windows and exterior doors',11),
('120-000','Plumbing',12),
('130-000','Electrical',13),
('140-000','HVAC',14),
('150-000','Insulation and air sealing',15),
('160-000','Drywall and plaster',16),
('170-000','Interior finish',17),
('180-000','Kitchen and bath',18),
('190-000','Porches, decks, pool',19),
('200-000','Appliances',20),
('300-000','Furniture',21)
on conflict (code) do nothing;

insert into library_subtasks (code, division_code, name, sort_order) values
-- 010 General requirements
('010-010','010-000','Plans and specifications',1),
('010-020','010-000','Plan review',2),
('010-030','010-000','Permits: zoning, building, environmental, other',3),
('010-040','010-000','Survey',4),
('010-050','010-000','Impact fee',5),
('010-060','010-000','Administrative costs',6),
('010-070','010-000','Financing costs',7),
('010-080','010-000','Legal fees',8),
('010-090','010-000','Engineering fees',9),
('010-100','010-000','Insurance',10),
('010-110','010-000','General contractor',11),
-- 020 Site prep
('020-010','020-000','Demolition (remodel)',1),
('020-020','020-000','Jacking and shoring (remodel)',2),
('020-030','020-000','Dust control, surface protection (remodel)',3),
('020-040','020-000','Job-site access',4),
('020-050','020-000','Job-site security',5),
('020-060','020-000','Dumpster and removal',6),
('020-070','020-000','Clear lot',7),
('020-080','020-000','Storage on site',8),
('020-090','020-000','Portable toilet',9),
('020-100','020-000','Temporary power',10),
('020-110','020-000','Temporary heat',11),
('020-120','020-000','Scaffolding rental',12),
('020-130','020-000','Tool and equipment rental',13),
-- 030 On-site water and sewer
('030-010','030-000','Soil and perc tests',1),
('030-020','030-000','Septic system design',2),
('030-030','030-000','Septic permits, inspections, fees',3),
('030-040','030-000','Septic system installation, tie-in to house',4),
('030-050','030-000','Well, pump, trenching, plumbing to house, pressure tank',5),
('030-060','030-000','Well permits and fees',6),
-- 040 Utilities
('040-010','040-000','Town water: tap fees and hookup',1),
('040-020','040-000','Town sewer: tap fees and hookup',2),
('040-030','040-000','Electrical: permit, connection fee, installation',3),
('040-040','040-000','Gas: permit, connection fee, hookup',4),
('040-050','040-000','LPG: tank installation, hookup',5),
('040-060','040-000','Oil tank installation',6),
('040-070','040-000','Telecom hookup',7),
-- 050 Excavation and earthwork
('050-010','050-000','Cut and fill',1),
('050-020','050-000','Blasting',2),
('050-030','050-000','Removal of stone and dirt',3),
('050-040','050-000','Rough grading',4),
('050-050','050-000','Trenching for utility hookups',5),
('050-060','050-000','Foundation excavation',6),
('050-070','050-000','Foundation footing drains',7),
('050-080','050-000','Backfill',8),
('050-090','050-000','Compaction',9),
('050-100','050-000','Curtain drains',10),
('050-110','050-000','Swales',11),
('050-120','050-000','Retaining walls',12),
('050-130','050-000','Pool',13),
('050-140','050-000','Other site drainage',14),
('050-160','050-000','Topsoil',15),
('050-170','050-000','Finish grading',16),
('050-180','050-000','Seeding and sod',17),
('050-190','050-000','Plantings, landscaping',18),
-- 060 Foundation
('060-010','060-000','Footings and pads',1),
('060-020','060-000','Foundation walls, stem walls, grade beams',2),
('060-030','060-000','Piers',3),
('060-040','060-000','Slabs: foundation, basement, garage',4),
('060-050','060-000','Steel reinforcing',5),
('060-060','060-000','Anchor bolts, hold-downs',6),
('060-070','060-000','Bulkheads',7),
('060-080','060-000','Sub-slab vapor barrier',8),
('060-090','060-000','Sump pump',9),
('060-110','060-000','Crawlspace vapor barrier',10),
('060-120','060-000','Crawlspace vents',11),
('060-130','060-000','Foundation windows',12),
('060-140','060-000','Dampproofing, waterproofing',13),
('060-150','060-000','Foundation drain board',14),
('060-160','060-000','Slab insulation: edge and below',15),
('060-170','060-000','Exterior foundation insulation',16),
('060-180','060-000','Exterior insulation coating and protection',17),
-- 070 Other masonry and paving
('070-010','070-000','Patios',1),
('070-020','070-000','Exterior stairs',2),
('070-030','070-000','Masonry chimneys',3),
('070-040','070-000','Fireplaces and hearths',4),
('070-050','070-000','Driveway',5),
('070-060','070-000','Walkways',6),
-- 080 Rough framing
('080-010','080-000','Sill and seal',1),
('080-020','080-000','Steel or wood carrying beam, lolly columns',2),
('080-030','080-000','Floor framing',3),
('080-040','080-000','Exterior and interior walls, rough stairs',4),
('080-050','080-000','Sheathing, subflooring',5),
('080-060','080-000','Roof framing and trusses',6),
('080-070','080-000','Subfascia',7),
('080-080','080-000','Steel framing connectors',8),
('080-090','080-000','Nails, screws, fasteners',9),
('080-100','080-000','Prep for plaster and drywall',10),
('080-110','080-000','Rough framing, labor only',11),
-- 090 Roofing
('090-010','090-000','Underlayment',1),
('090-020','090-000','Membrane',2),
('090-030','090-000','Flashing: chimney, vent pipes, sidewalls, other penetrations',3),
('090-040','090-000','Drip edge',4),
('090-050','090-000','Roofing installation',5),
('090-060','090-000','Gutters and downspouts',6),
('090-070','090-000','Skylights',7),
('090-080','090-000','Ridge and roof vents',8),
-- 100 Exterior
('100-010','100-000','Exterior foam sheathing',1),
('100-020','100-000','Weather barrier (Tyvek, etc.)',2),
('100-030','100-000','Membrane and flashing',3),
('100-040','100-000','Vinyl or composite siding',4),
('100-050','100-000','Wood siding',5),
('100-060','100-000','Brick veneer',6),
('100-070','100-000','Stone veneer',7),
('100-080','100-000','Stucco',8),
('100-090','100-000','Fascia, soffit, frieze, corner boards, water table',9),
('100-100','100-000','Soffit and gable vents',10),
('100-110','100-000','Window and door trim',11),
('100-120','100-000','Other exterior trim',12),
('100-130','100-000','Exterior stairs and landing',13),
('100-140','100-000','Exterior paint, stain, caulk',14),
('100-150','100-000','Exterior, labor only',15),
-- 110 Windows and exterior doors
('110-010','110-000','Membrane and flashing',1),
('110-020','110-000','Exterior doors, prehung',2),
('110-030','110-000','Exterior door slabs',3),
('110-040','110-000','Exterior door frames and sills',4),
('110-050','110-000','Sidelights and transoms',5),
('110-060','110-000','Locksets, knobs, door hardware',6),
('110-070','110-000','Patio doors: sliding or hinged',7),
('110-080','110-000','Windows',8),
('110-090','110-000','Garage doors and opener',9),
-- 120 Plumbing
('120-010','120-000','Drain, waste, vent',1),
('120-020','120-000','Water supply piping',2),
('120-030','120-000','Gas piping',3),
('120-040','120-000','Water treatment',4),
('120-050','120-000','Water heater',5),
('120-060','120-000','Fixtures: toilets, tubs, sinks, showers',6),
('120-070','120-000','Faucets, mixing valves, shower heads',7),
('120-080','120-000','Disposal',8),
-- 130 Electrical
('130-010','130-000','Service panel, sub-panels',1),
('130-020','130-000','Rough wiring',2),
('130-030','130-000','Phone, cable, internet wiring',3),
('130-040','130-000','Lighting fixtures',4),
('130-050','130-000','Low-voltage fixtures and transformers',5),
('130-060','130-000','Exterior lighting',6),
('130-070','130-000','Devices: outlets, switches, dimmers',7),
('130-080','130-000','Lighting control system',8),
('130-090','130-000','Doorbell system',9),
('130-100','130-000','Smoke and CO alarms',10),
('130-110','130-000','Intercom system',11),
('130-120','130-000','Security system',12),
('130-130','130-000','Home theater and entertainment',13),
-- 140 HVAC
('140-010','140-000','Furnace or heat pump',1),
('140-020','140-000','Central AC',2),
('140-030','140-000','Air handler',3),
('140-040','140-000','Ductwork, grilles, registers',4),
('140-050','140-000','Air filter',5),
('140-060','140-000','Boiler and piping',6),
('140-070','140-000','Radiators',7),
('140-080','140-000','Whole-house ventilation (HRV, ERV, exhaust only, other)',8),
('140-090','140-000','HVAC controls',9),
('140-100','140-000','Solar hot water',10),
-- 150 Insulation and air sealing
('150-010','150-000','Roof and attic insulation',1),
('150-020','150-000','Roof and eave baffles',2),
('150-030','150-000','Wall cavity insulation',3),
('150-040','150-000','Foam board insulation',4),
('150-050','150-000','Spray foam insulation',5),
('150-060','150-000','Basement insulation (interior)',6),
('150-070','150-000','Crawlspace insulation',7),
('150-080','150-000','Air sealing',8),
('150-090','150-000','Energy diagnostics (blower door, infrared)',9),
-- 160 Drywall and plaster
('160-010','160-000','Walls',1),
('160-020','160-000','Ceilings and soffits',2),
('160-030','160-000','Decorative plaster',3),
('160-040','160-000','Drywall, labor only',4),
-- 170 Interior finish
('170-010','170-000','Interior doors, prehung',1),
('170-020','170-000','Interior door slabs',2),
('170-030','170-000','Interior door frames, thresholds',3),
('170-040','170-000','Door knobs, hardware',4),
('170-050','170-000','Interior trim: baseboard, casings, crown, chair rail, other',5),
('170-060','170-000','Wainscoting, paneling',6),
('170-070','170-000','Built-in shelving, cabinets',7),
('170-080','170-000','Closet shelving, hardware',8),
('170-090','170-000','Stairs, railings, newels',9),
('170-100','170-000','Interior painting, staining',10),
('170-110','170-000','Wood flooring',11),
('170-120','170-000','Carpeting',12),
('170-130','170-000','Resilient and vinyl flooring',13),
('170-140','170-000','Ceramic tile and stone (with underlayment, surface prep)',14),
('170-150','170-000','Other flooring',15),
('170-160','170-000','Acoustical, metal, decorative ceilings',16),
('170-170','170-000','Interior carpentry, labor only',17),
-- 180 Kitchen and bath
('180-010','180-000','Kitchen cabinets',1),
('180-020','180-000','Bath cabinets',2),
('180-030','180-000','Cabinet pulls and hardware',3),
('180-040','180-000','Countertops and backsplash',4),
('180-050','180-000','Ceramic tile and stone',5),
('180-060','180-000','Raised tub platform',6),
('180-070','180-000','Tub enclosure',7),
('180-080','180-000','Shower enclosure and doors',8),
('180-090','180-000','Medicine cabinets',9),
('180-100','180-000','Mirrors',10),
('180-110','180-000','Towel hangers, toilet paper holders, accessories',11),
('180-120','180-000','Kitchen and bath, labor only',12),
-- 190 Porches, decks, pool
('190-010','190-000','Porch',1),
('190-020','190-000','Pool or hot tub',2),
('190-030','190-000','Wood or composite deck',3),
('190-040','190-000','Fencing',4),
('190-050','190-000','Other outdoor structures',5),
-- 200 Appliances
('200-010','200-000','Refrigerator',1),
('200-020','200-000','Range and cooktop',2),
('200-030','200-000','Microwave',3),
('200-040','200-000','Range hood',4),
('200-050','200-000','Dishwasher',5),
('200-060','200-000','Washer and dryer',6),
-- 300 Furniture
('300-010','300-000','Electronics',1),
('300-020','300-000','Kitchen',2),
('300-030','300-000','Dining',3),
('300-040','300-000','Living room',4),
('300-050','300-000','Bedroom',5),
('300-060','300-000','Bathroom',6),
('300-070','300-000','Outdoor',7)
on conflict (code) do nothing;
