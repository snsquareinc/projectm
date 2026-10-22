-- Phase 5: vendor payment confirmation links, for contractors to confirm payments without signing in.
-- Run once after 010. Safe to re-run.

create extension if not exists pgcrypto with schema extensions;

-- One row per link sent to a contractor. Only a hash of the secret token is stored.
create table if not exists payment_confirmations (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  vendor_id uuid not null references vendors(id) on delete cascade,
  token_hash text not null unique,
  payment_ids uuid[] not null,
  contract_amount numeric not null default 0,
  paid_to_date numeric not null default 0,
  expires_on date not null,
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  response text check (response in ('Confirmed', 'Disputed')),
  responder_name text not null default '',
  response_note text not null default ''
);

alter table payment_confirmations enable row level security;

drop policy if exists "signed-in full access" on payment_confirmations;
create policy "signed-in full access" on payment_confirmations for all to authenticated using (true) with check (true);

-- Public page: look up one confirmation by its secret token. Returns null if the token is wrong or expired.
create or replace function get_payment_confirmation(p_token text)
returns json language plpgsql security definer set search_path = public, extensions as $$
declare c payment_confirmations%rowtype;
begin
  select * into c from payment_confirmations
   where token_hash = encode(digest(p_token, 'sha256'), 'hex') and expires_on >= current_date;
  if not found then return null; end if;
  return json_build_object(
    'project_name', (select name from projects where id = c.project_id),
    'project_address', (select coalesce(address, '') from projects where id = c.project_id),
    'lender', (select coalesce(lender, '') from projects where id = c.project_id),
    'vendor_name', (select name from vendors where id = c.vendor_id),
    'contract_amount', c.contract_amount,
    'paid_to_date', c.paid_to_date,
    'balance', c.contract_amount - c.paid_to_date,
    'expires_on', c.expires_on,
    'responded_at', c.responded_at,
    'response', c.response,
    'payments', (select coalesce(json_agg(json_build_object(
                    'id', p.id, 'pay_date', p.pay_date, 'amount', p.amount,
                    'method', p.method, 'reference', p.reference) order by p.pay_date), '[]'::json)
                 from payments p where p.id = any(c.payment_ids))
  );
end $$;

-- Public page: record the contractor's answer. The first answer stands.
create or replace function respond_payment_confirmation(p_token text, p_name text, p_response text, p_note text)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare c payment_confirmations%rowtype;
begin
  if p_response not in ('Confirmed', 'Disputed') then raise exception 'Choose Confirmed or Disputed.'; end if;
  if coalesce(trim(p_name), '') = '' then raise exception 'Enter your full name.'; end if;
  select * into c from payment_confirmations
   where token_hash = encode(digest(p_token, 'sha256'), 'hex') and expires_on >= current_date
   for update;
  if not found then raise exception 'This link is not valid or has expired.'; end if;
  if c.responded_at is not null then raise exception 'This has already been answered.'; end if;
  update payment_confirmations
     set responded_at = now(), response = p_response,
         responder_name = trim(p_name), response_note = left(coalesce(p_note, ''), 1000)
   where id = c.id;
  update payments
     set status = p_response, confirmed_name = trim(p_name), confirmed_at = now()
   where id = any(c.payment_ids);
end $$;

grant execute on function get_payment_confirmation(text) to anon, authenticated;
grant execute on function respond_payment_confirmation(text, text, text, text) to anon, authenticated;
