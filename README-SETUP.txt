تشغيل الحفظ الدائم بـ Supabase (مجاني) — مرة واحدة فقط
=======================================================

1) ادخل https://supabase.com  -> Start your project -> سجّل (ممكن بحساب GitHub).
2) New project: اكتب أي اسم + Database Password (احفظه) + اختار أقرب منطقة -> Create.
   استنى دقيقتين لحد ما يجهز.

3) أنشئ الأدمن:
   القائمة الشمال: Authentication -> Users -> Add user -> Create new user
   اكتب إيميلك وباسورد قوي، وفعّل "Auto Confirm User".  ← ده اللي هتدخل بيه لوحة التحكم.
   ثم: Authentication -> Sign In / Providers (أو Settings) -> اقفل "Allow new users to sign up".
   (مهم عشان محدش غيرك يعمل حساب.)

4) القائمة الشمال: SQL Editor -> New query -> الصق الكود ده كله (غيّر الإيميل بإيميلك) -> Run:

-------------------------------------------------------
create table if not exists public.kv (
  path text primary key,
  val  jsonb not null
);

alter table public.kv enable row level security;

create policy "public read" on public.kv
  for select to anon, authenticated using (true);

create policy "admin write" on public.kv
  for all to authenticated
  using      ((auth.jwt() ->> 'email') = 'PUT-YOUR-ADMIN-EMAIL-HERE')
  with check ((auth.jwt() ->> 'email') = 'PUT-YOUR-ADMIN-EMAIL-HERE');

create or replace function public.increment_stat(field text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if field not in ('views','followers') then
    raise exception 'bad field';
  end if;
  insert into public.kv(path, val)
  values ('stats/main', jsonb_build_object(field, 1))
  on conflict (path) do update
    set val = public.kv.val
        || jsonb_build_object(field, coalesce((public.kv.val ->> field)::bigint, 0) + 1);
end $$;

grant execute on function public.increment_stat(text) to anon, authenticated;
-------------------------------------------------------

5) هات القيمتين:
   - Project URL:  Project Settings (⚙) -> General  (أو من زرار Connect فوق)
                   شكله: https://abcdxyz.supabase.co
   - المفتاح العام: Project Settings -> API Keys
        * تبويب "API Keys": لو مفيش Publishable key دوس "Create new API Keys"
          وانسخ الـ Publishable key (بيبدأ بـ sb_publishable_)
        * أو تبويب "Legacy API Keys": انسخ مفتاح anon
     أي واحد منهم يشتغل. ممنوع تنسخ secret أو service_role.

6) افتح index.html ودوّر على GD_CONFIG وعبّي:

   supabaseUrl: 'Project URL',
   anonKey:     'الـ Publishable key أو anon',
   adminEmail:  'إيميل الأدمن من خطوة 3'

7) ارفع الملفات على GitHub.

الدخول للوحة التحكم: admin.html (أو index.html#admin) وتكتب باسورد الأدمن من خطوة 3.

ملاحظات:
- ماتحطش أبدًا مفتاح service_role في الموقع.
- لو سبت GD_CONFIG فاضي الموقع يشتغل زي الأول (تخزين في المتصفح بس).
- الصور اللي بترفعها من الأدمن بتتضغط وتتخزن في الجدول، فاستخدم صور مش كبيرة.
