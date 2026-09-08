-- =============================================================
-- مخطط قاعدة البيانات لموقع «بيّنات» — منهج ترياق
-- شغّل هذا الملف في: Supabase Dashboard → SQL Editor → New query
--
-- الصفحة تعمل بلا Supabase (تخزينٌ محليّ)، وهذه الجداول تجعل تقدّم
-- الدارس وإجاباته وملاحظات المعلّم تتبعه على أي جهاز.
-- =============================================================
-- ------------------------------------------------------------
-- ١) تقدّم القراءة في «ترياق»
-- ------------------------------------------------------------
create table if not exists public.tiryaq_progress (
  session_id  text primary key,
  page        integer     not null default 1,
  read_pages  integer[]   not null default '{}',
  marks       integer[]   not null default '{}',
  role        text        not null default 'student',
  updated_at  timestamptz not null default now()
);

-- ------------------------------------------------------------
-- ٢) إجابات تمارين «ترياق» — صفٌّ لكل سؤالٍ أُجيب عنه
-- ------------------------------------------------------------
create table if not exists public.tiryaq_quiz (
  session_id     text        not null,
  question_index integer     not null,
  chapter        integer     not null default 0,
  chosen         integer     not null,
  is_correct     boolean     not null,
  answered_at    timestamptz not null default now(),
  constraint tiryaq_quiz_pk primary key (session_id, question_index)
);

create index if not exists tiryaq_quiz_chapter_idx on public.tiryaq_quiz (chapter);

-- ------------------------------------------------------------
-- ٣) تصنيف بطاقات المصطلحات: أعرفها / أراجعها
-- ------------------------------------------------------------
create table if not exists public.tiryaq_cards (
  session_id text        not null,
  term_index integer     not null,
  state      text        not null check (state in ('known', 'review')),
  updated_at timestamptz not null default now(),
  constraint tiryaq_cards_pk primary key (session_id, term_index)
);

-- ------------------------------------------------------------
-- ٤) ملاحظات المعلّم على صفحات المتن
-- ------------------------------------------------------------
create table if not exists public.tiryaq_notes (
  session_id text        not null,
  page       integer     not null,
  note       text        not null default '',
  updated_at timestamptz not null default now(),
  constraint tiryaq_notes_pk primary key (session_id, page)
);

-- ------------------------------------------------------------
-- ٥) أمان مستوى الصف لجداول «ترياق»
--    كسابقتها: لا تسجيل دخول، بل معرّف جلسةٍ يُولَّد في المتصفح.
-- ------------------------------------------------------------
alter table public.tiryaq_progress enable row level security;
alter table public.tiryaq_quiz     enable row level security;
alter table public.tiryaq_cards    enable row level security;
alter table public.tiryaq_notes    enable row level security;

do $$
declare t text;
begin
  foreach t in array array['tiryaq_progress', 'tiryaq_quiz', 'tiryaq_cards', 'tiryaq_notes'] loop
    execute format('drop policy if exists "%s anon read"   on public.%I', t, t);
    execute format('drop policy if exists "%s anon write"  on public.%I', t, t);
    execute format('drop policy if exists "%s anon update" on public.%I', t, t);
    execute format('drop policy if exists "%s anon delete" on public.%I', t, t);

    execute format('create policy "%s anon read"   on public.%I for select using (true)', t, t);
    execute format('create policy "%s anon write"  on public.%I for insert with check (true)', t, t);
    execute format('create policy "%s anon update" on public.%I for update using (true) with check (true)', t, t);
    execute format('create policy "%s anon delete" on public.%I for delete using (true)', t, t);
  end loop;
end $$;

-- ------------------------------------------------------------
-- ٦) عرضٌ إحصائي لأسئلة «ترياق»: أكثر المسائل إشكالاً على الطلبة
-- ------------------------------------------------------------
create or replace view public.tiryaq_question_stats as
select
  chapter,
  question_index,
  count(*)                                          as attempts,
  count(*) filter (where is_correct)                as correct,
  round(100.0 * count(*) filter (where is_correct) / nullif(count(*), 0), 1) as success_rate
from public.tiryaq_quiz
group by chapter, question_index
order by chapter, question_index;
