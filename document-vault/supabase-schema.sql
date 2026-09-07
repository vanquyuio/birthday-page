-- Kho Giấy Tờ Thông Minh - Supabase schema
-- Chạy toàn bộ file này trong Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  ocr_text text default '',
  image_path text not null,
  original_name text,
  mime_type text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists documents_user_created_idx on public.documents(user_id, created_at desc);
create index if not exists documents_title_idx on public.documents(title);

alter table public.documents enable row level security;

revoke all on table public.documents from anon;
grant select, insert, update, delete on table public.documents to authenticated;

create policy "Users can view own documents"
on public.documents for select to authenticated
using (auth.uid() = user_id);

create policy "Users can insert own documents"
on public.documents for insert to authenticated
with check (auth.uid() = user_id);

create policy "Users can update own documents"
on public.documents for update to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own documents"
on public.documents for delete to authenticated
using (auth.uid() = user_id);

-- Bucket ảnh giấy tờ: PRIVATE, không công khai.
insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict (id) do update set public = false;

create policy "Users can read own document files"
on storage.objects for select to authenticated
using (
  bucket_id = 'documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can upload own document files"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can delete own document files"
on storage.objects for delete to authenticated
using (
  bucket_id = 'documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);
