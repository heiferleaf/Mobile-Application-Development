export  interface DateParts {
  year : string,
  month: string,
  day  : string
}

export function getTodayStr() : DateParts {
  const d = new Date();
  const year = `${d.getFullYear()}`;
  const month = `${d.getMonth() + 1}月`;
  const day = `${d.getDay()}日`;
  return { year, month, day }
}