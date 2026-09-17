/**
 * Arabic dictionary for the approval namespace.
 * Will be expanded to cover all 45 namespaces.
 */
const zhKeys = {
  waiting: '',
  'detail.aria': '',
  escalation: '',
  reject: '',
  allowOnce: '',
} satisfies Record<string, string>

/** Arabic dictionary, checked against the Chinese key set. */
export const ar = {
  waiting: 'بانتظار الموافقة',
  'detail.aria': 'تفاصيل الموافقة',
  escalation: 'الأداة {toolName} تطلب تنفيذاً بصلاحية أعلى',
  reject: 'رفض',
  allowOnce: 'السماح مرة واحدة',
} satisfies Record<keyof typeof zhKeys, string>

/** `settings.theme` namespace — Arabic. */
export const themeAr = {
  'appearance.title': 'المظهر',
  'appearance.light': 'فاتح',
  'appearance.dark': 'داكن',
  'appearance.system': 'حسب النظام',
  'fontSize.title': 'حجم الخط',
  'fontSize.description': 'يؤثر فقط على حجم نص المحادثة',
  'fontSize.unit': 'بكسل',
  'fontSize.increase': 'تكبير الخط',
  'fontSize.decrease': 'تصغير الخط',
} as const

/** `sidebar` namespace — Arabic. */
export const sidebarAr = {
  'session.new': 'محادثة جديدة',
  'session.new.label': 'محادثة جديدة',
  'toggle.open': 'فتح الشريط الجانبي',
  'toggle.collapse': 'طي الشريط الجانبي',
  'panels.label': 'اللوحات العامة',
} as const

/** `settings.locale` namespace — Arabic. */
export const settingsLocaleAr = {
  'language.title': 'اللغة',
} as const
