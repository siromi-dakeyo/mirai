-- ============================================================
-- ご意見番機能用テーブル定義
-- Supabase の SQL Editor で実行してください（再実行しても安全）
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

-- RLSを有効化。テーブル所有者にも例外なく適用する（FORCE）。
alter table public.feedback enable row level security;
alter table public.feedback force row level security;

-- 既存ポリシーがあれば一旦削除してから再作成（再実行時のエラー防止）
drop policy if exists "feedback_insert_anon"  on public.feedback;
drop policy if exists "feedback_select_deny"  on public.feedback;
drop policy if exists "feedback_update_deny"  on public.feedback;
drop policy if exists "feedback_delete_deny"  on public.feedback;

-- 1) INSERT：anon / authenticated からの投稿のみ許可
--    テーブル自体のcheck制約（文字数）が同時に適用される
create policy "feedback_insert_anon"
  on public.feedback
  for insert
  to anon, authenticated
  with check (true);

-- 2) SELECT：一般ロールからは一切参照不可（明示的に拒否）
--    ※ Supabaseダッシュボード／service_roleキーはRLSを
--      バイパスするため、管理側からは引き続き閲覧できる
create policy "feedback_select_deny"
  on public.feedback
  for select
  to anon, authenticated
  using (false);

-- 3) UPDATE：一般ロールからは一切更新不可
create policy "feedback_update_deny"
  on public.feedback
  for update
  to anon, authenticated
  using (false)
  with check (false);

-- 4) DELETE：一般ロールからは一切削除不可
create policy "feedback_delete_deny"
  on public.feedback
  for delete
  to anon, authenticated
  using (false);

-- ------------------------------------------------------------
-- （任意）投稿一覧を公開ページに表示したくなった場合の例
-- 上の feedback_select_deny を drop policy してから、
-- 以下のような緩い SELECT ポリシーに差し替えてください。
-- ------------------------------------------------------------
-- drop policy if exists "feedback_select_deny" on public.feedback;
-- create policy "feedback_select_public"
--   on public.feedback
--   for select
--   to anon, authenticated
--   using (true);
