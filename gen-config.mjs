/**
 * يولّد config.js من متغيرات البيئة قبل النشر.
 *
 * صفحة «ترياق» ملفٌّ ساكنٌ لا يمرّ ببناءٍ يحقن المتغيرات، وهذا السكربت
 * يكتب إلى جانبها سطراً واحداً تقرأه. اجعله أمر البناء في Vercel:
 *
 *     node gen-config.mjs
 *
 * وإن لم تُضبط المتغيرات كتب قيماً فارغة، فتبقى الصفحة على التخزين المحلي.
 */
import { writeFileSync } from 'node:fs';

const config = {
  url: process.env.NEXT_PUBLIC_SUPABASE_URL ?? '',
  key: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? '',
};

writeFileSync(
  new URL('./config.js', import.meta.url),
  `window.TIRYAQ_SUPABASE=${JSON.stringify(config)};\n`,
);

console.log(config.url ? 'config.js: مضبوط على Supabase' : 'config.js: فارغ — تخزينٌ محليّ');
