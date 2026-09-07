-- Kho Giấy Tờ Thông Minh - chế độ công khai
-- Có thể chạy lại nhiều lần để chuyển từ phiên bản có đăng nhập sang không cần đăng nhập.

create extension if not exists pgcrypto;

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  title text not null,
  ocr_text text default '',
  image_path text not null,
  original_name text,
  mime_type text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Phiên bản mới không yêu cầu tài khoản.
alter table public.documents alter column user_id drop not null;
create index if not exists documents_created_idx on public.documents(created_at desc);
create index if not exists documents_title_idx on public.documents(title);
alter table public.documents enable row level security;

-- Xóa policy cũ của phiên bản có đăng nhập.
drop policy if exists "Users can view own documents" on public.documents;
drop policy if exists "Users can insert own documents" on public.documents;
drop policy if exists "Users can update own documents" on public.documents;
drop policy if exists "Users can delete own documents" on public.documents;

-- Cho phép mọi người xem, thêm, sửa và xóa giấy tờ.
drop policy if exists "Public can view documents" on public.documents;
drop policy if exists "Public can insert documents" on public.documents;
drop policy if exists "Public can update documents" on public.documents;
drop policy if exists "Public can delete documents" on public.documents;

create policy "Public can view documents"
on public.documents for select to anon, authenticated
using (true);

create policy "Public can insert documents"
on public.documents for insert to anon, authenticated
with check (true);

create policy "Public can update documents"
on public.documents for update to anon, authenticated
using (true) with check (true);

create policy "Public can delete documents"
on public.documents for delete to anon, authenticated
using (true);

grant select, insert, update, delete on table public.documents to anon, authenticated;

-- Storage bucket giữ private nhưng policy cho phép website tạo signed URL.
insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict (id) do update set public = false;

-- Xóa policy cũ của Storage.
drop policy if exists "Users can read own document files" on storage.objects;
drop policy if exists "Users can upload own document files" on storage.objects;
drop policy if exists "Users can delete own document files" on storage.objects;
drop policy if exists "Public can read document files" on storage.objects;
drop policy if exists "Public can upload document files" on storage.objects;
drop policy if exists "Public can delete document files" on storage.objects;

create policy "Public can read document files"
on storage.objects for select to anon, authenticated
using (bucket_id = 'documents');

create policy "Public can upload document files"
on storage.objects for insert to anon, authenticated
with check (bucket_id = 'documents');

create policy "Public can delete document files"
on storage.objects for delete to anon, authenticated
using (bucket_id = 'documents');
