export type Language = "en" | "zh" | "ru";

export function getLocale(lang: Language): string {
  if (lang === "zh") return "zh-CN";
  if (lang === "ru") return "ru-RU";
  return "en-US";
}

export function formatDate(
  date: Date,
  lang: Language,
  options: Intl.DateTimeFormatOptions = {
    year: "numeric",
    month: "short",
    day: "numeric",
  },
): string {
  return new Intl.DateTimeFormat(getLocale(lang), options).format(date);
}

export function formatTime(
  date: Date,
  lang: Language,
  options: Intl.DateTimeFormatOptions = { hour: "2-digit", minute: "2-digit" },
): string {
  return new Intl.DateTimeFormat(getLocale(lang), options).format(date);
}
