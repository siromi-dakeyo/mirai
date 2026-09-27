-- ============================================================
-- ご意見番機能用テーブル定義
-- Supabase の SQL Editor で実行してください
-- ============================================================

create table if not exists public.feedback (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(trim(name)) between 1 and 100),
  message     text not null check (char_length(trim(message)) between 1 and 2000),
  created_at  timestamptz not null default now()
);

comment on table public.feedback is 'ご意見番フォームからの投稿';
comment on column public.feedback.name is 'お名前（ニックネーム可）';
comment on column public.feedback.message is 'ご意見本文';

-- 新着順で見るためのインデックス
create index if not exists feedback_created_at_idx
  on public.feedback (created_at desc);

-- ------------------------------------------------------------
-- RLS（Row Level Security）
-- ------------------------------------------------------------
alter table public.feedback enable row level security;

-- 誰でも投稿（INSERT）できるようにする
-- ※ フロントから anon key で叩く想定
create policy "Anyone can submit feedback"
  on public.feedback
  for insert
  to anon, authenticated
  with check (true);

-- 閲覧（SELECT）・更新・削除のポリシーはあえて作成しない
-- → 一般ユーザーからは読めず、Supabase ダッシュボードや
--    service_role キー（サーバー側）からのみ内容を確認できる。
-- もし投稿一覧を公開ページに表示したくなったら、
-- 以下のような SELECT ポリシーを追加してください（今は未使用）。
--
-- create policy "Anyone can read feedback"
--   on public.feedback
--   for select
--   to anon, authenticated
--   using (true);
