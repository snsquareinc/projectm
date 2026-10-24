-- Phase 5b: finger signature on payment confirmations. Run once after 011. Safe to re-run.

alter table payment_confirmations add column if not exists signature_image text not null default '';

-- The answer function now also takes the signature. Replace the old version.
drop function if exists respond_payment_confirmation(text, text, text, text);

create or replace function respond_payment_confirmation(p_token text, p_name text, p_response text, p_note text, p_signature text)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare c payment_confirmations%rowtype;
begin
  if p_response not in ('Confirmed', 'Disputed') then raise exception 'Choose Confirmed or Disputed.'; end if;
  if coalesce(trim(p_name), '') = '' then raise exception 'Enter your full name.'; end if;
  if coalesce(p_signature, '') not like 'data:image/png;base64,%' or length(p_signature) > 200000 then
    raise exception 'Sign with your finger first.';
  end if;
  select * into c from payment_confirmations
   where token_hash = encode(digest(p_token, 'sha256'), 'hex') and expires_on >= current_date
   for update;
  if not found then raise exception 'This link is not valid or has expired.'; end if;
  if c.responded_at is not null then raise exception 'This has already been answered.'; end if;
  update payment_confirmations
     set responded_at = now(), response = p_response,
         responder_name = trim(p_name), response_note = left(coalesce(p_note, ''), 1000),
         signature_image = p_signature
   where id = c.id;
  update payments
     set status = p_response, confirmed_name = trim(p_name), confirmed_at = now()
   where id = any(c.payment_ids);
end $$;

grant execute on function respond_payment_confirmation(text, text, text, text, text) to anon, authenticated;
