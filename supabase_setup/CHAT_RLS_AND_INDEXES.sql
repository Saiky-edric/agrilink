-- CHAT RLS, Indexes, and Trigger Migration
-- Safe to run multiple times with IF NOT EXISTS guards where possible

-- 1) Enable RLS
alter table if exists public.conversations enable row level security;
alter table if exists public.messages enable row level security;

-- 2) Policies for conversations
-- Drop existing policies if needed (optional, uncomment if replacing)
-- drop policy if exists conversations_select_participants_only on public.conversations;
-- drop policy if exists conversations_insert_participants_only on public.conversations;
-- drop policy if exists conversations_update_participants_only on public.conversations;

-- Drop and recreate policies to avoid IF NOT EXISTS (not supported on current Postgres)

-- Conversations policies
drop policy if exists conversations_select_participants_only on public.conversations;
drop policy if exists conversations_insert_participants_only on public.conversations;
drop policy if exists conversations_update_participants_only on public.conversations;

create policy conversations_select_participants_only
on public.conversations
for select
using (
  buyer_id = auth.uid() or farmer_id = auth.uid()
);

create policy conversations_insert_participants_only
on public.conversations
for insert
with check (
  buyer_id = auth.uid() or farmer_id = auth.uid()
);

create policy conversations_update_participants_only
on public.conversations
for update
using (
  buyer_id = auth.uid() or farmer_id = auth.uid()
)
with check (
  buyer_id = auth.uid() or farmer_id = auth.uid()
);

-- Messages policies
drop policy if exists messages_select_participants_only on public.messages;
drop policy if exists messages_insert_participants_only on public.messages;
drop policy if exists messages_update_read_by_non_sender on public.messages;

create policy messages_select_participants_only
on public.messages
for select
using (
  exists (
    select 1 from public.conversations c
    where c.id = messages.conversation_id
      and (c.buyer_id = auth.uid() or c.farmer_id = auth.uid())
  )
);

create policy messages_insert_participants_only
on public.messages
for insert
with check (
  sender_id = auth.uid() and
  exists (
    select 1 from public.conversations c
    where c.id = messages.conversation_id
      and (c.buyer_id = auth.uid() or c.farmer_id = auth.uid())
  )
);

create policy messages_update_read_by_non_sender
on public.messages
for update
using (
  exists (
    select 1 from public.conversations c
    where c.id = messages.conversation_id
      and (c.buyer_id = auth.uid() or c.farmer_id = auth.uid())
  )
  and sender_id <> auth.uid()
)
with check (true);

-- 4) Helpful indexes
create index if not exists idx_conversations_buyer on public.conversations (buyer_id);
create index if not exists idx_conversations_farmer on public.conversations (farmer_id);
create index if not exists idx_conversations_last_message_at on public.conversations (last_message_at desc);
create index if not exists idx_messages_conversation on public.messages (conversation_id, created_at);

-- 5) Optional trigger to update last_message and last_message_at when a message is inserted
create or replace function public.update_conversation_last_message()
returns trigger language plpgsql as $$
begin
  update public.conversations
  set last_message = new.content,
      last_message_at = new.created_at,
      updated_at = now()
  where id = new.conversation_id;
  return new;
end $$;

drop trigger if exists trg_messages_update_conversation on public.messages;
create trigger trg_messages_update_conversation
after insert on public.messages
for each row execute function public.update_conversation_last_message();
