export const MIN_EPHEMERIS_YEAR = 1550;
export const MAX_EPHEMERIS_YEAR = 2650;

export function normalizeStoredState(raw) {
  const stored = raw && typeof raw === "object" && !Array.isArray(raw) ? raw : {};
  const isRecord = (value) => value && typeof value === "object" && !Array.isArray(value);

  return {
    birth: isRecord(stored.birth) ? stored.birth : null,
    visited: Array.isArray(stored.visited)
      ? stored.visited.filter((house) => Number.isInteger(house) && house >= 0 && house < 12)
      : [],
    notes: isRecord(stored.notes) ? stored.notes : {},
    noteDates: isRecord(stored.noteDates) ? stored.noteDates : {}
  };
}

export function daysInMonth(year, month) {
  if (!Number.isInteger(year) || year < 1 || year > 9999 || !Number.isInteger(month) || month < 1 || month > 12) {
    return 0;
  }

  if (month === 2) {
    return year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0) ? 29 : 28;
  }

  return [4, 6, 9, 11].includes(month) ? 30 : 31;
}

export function normalizeBirth(raw, defaults = {}) {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    throw new TypeError("Birth details must be an object.");
  }

  const birth = { ...defaults, ...raw };
  birth.y = Number(birth.y);
  birth.m = Number(birth.m);
  birth.d = Number(birth.d);
  birth.utcOffset = Number(birth.utcOffset);
  birth.latitude = Number(birth.latitude);
  birth.longitude = Number(birth.longitude);
  birth.t = String(birth.t || "");
  birth.name = String(birth.name || "").trim().slice(0, 48);
  birth.houseSystem = birth.houseSystem === "wholeSign" ? "wholeSign" : birth.houseSystem;
  birth.zodiacMode = birth.zodiacMode === "sidereal" ? "sidereal" : birth.zodiacMode;

  if (!Number.isInteger(birth.y) || birth.y < MIN_EPHEMERIS_YEAR || birth.y > MAX_EPHEMERIS_YEAR) {
    throw new RangeError(`Birth year must be between ${MIN_EPHEMERIS_YEAR} and ${MAX_EPHEMERIS_YEAR}.`);
  }
  if (!Number.isInteger(birth.m) || birth.m < 1 || birth.m > 12) {
    throw new RangeError("Birth month must be between 1 and 12.");
  }
  if (!Number.isInteger(birth.d) || birth.d < 1 || birth.d > daysInMonth(birth.y, birth.m)) {
    throw new RangeError("The selected day is not valid for that month and year.");
  }
  if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(birth.t)) {
    throw new RangeError("Birth time must use 24-hour HH:MM format.");
  }
  if (!Number.isFinite(birth.utcOffset) || birth.utcOffset < -12 || birth.utcOffset > 14) {
    throw new RangeError("UTC offset must be between -12 and +14 hours.");
  }
  if (!Number.isFinite(birth.latitude) || birth.latitude < -90 || birth.latitude > 90) {
    throw new RangeError("Latitude must be between -90 and +90 degrees.");
  }
  if (!Number.isFinite(birth.longitude) || birth.longitude < -180 || birth.longitude > 180) {
    throw new RangeError("Longitude must be between -180 and +180 degrees.");
  }
  if (!["placidus", "wholeSign"].includes(birth.houseSystem)) {
    throw new RangeError("Choose Placidus or Whole Sign houses.");
  }
  if (!["tropical", "sidereal"].includes(birth.zodiacMode)) {
    throw new RangeError("Choose Tropical or Sidereal zodiac.");
  }

  return birth;
}

export function localDateTimeToUtcParts(year, month, day, time, utcOffset) {
  const [hour, minute, ...extra] = String(time).split(":").map(Number);
  if (
    !Number.isInteger(year) || year < 1 || year > 9999 ||
    !Number.isInteger(month) || month < 1 || month > 12 ||
    !Number.isInteger(day) || day < 1 || day > daysInMonth(year, month) ||
    !Number.isInteger(hour) || hour < 0 || hour > 23 ||
    !Number.isInteger(minute) || minute < 0 || minute > 59 ||
    extra.length !== 0 || !Number.isFinite(utcOffset) || utcOffset < -12 || utcOffset > 14
  ) {
    throw new RangeError("Invalid local birth date, time, or UTC offset.");
  }

  const localDate = new Date(0);
  localDate.setUTCHours(hour, minute, 0, 0);
  localDate.setUTCFullYear(year, month - 1, day);
  const utcDate = new Date(localDate.getTime() - utcOffset * 60 * 60 * 1000);

  return {
    year: utcDate.getUTCFullYear(),
    month: utcDate.getUTCMonth() + 1,
    day: utcDate.getUTCDate(),
    hour: utcDate.getUTCHours(),
    minute: utcDate.getUTCMinutes()
  };
}

export function wholeSignCusps(ascendant) {
  if (!Number.isFinite(ascendant)) {
    throw new TypeError("Ascendant longitude must be finite.");
  }

  const firstSign = Math.floor((((ascendant % 360) + 360) % 360) / 30);
  return Array.from({ length: 12 }, (_, index) => ((firstSign + index) % 12) * 30);
}

export function houseSectorInterval(houseIndex, cusps, ascendant) {
  if (!Array.isArray(cusps) || cusps.length !== 12 || cusps.some((cusp) => !Number.isFinite(cusp) || cusp < 0 || cusp >= 360) || !Number.isInteger(houseIndex) || houseIndex < 0 || houseIndex > 11 || !Number.isFinite(ascendant)) {
    throw new TypeError("House sectors require 12 cusps, a valid house index, and a finite Ascendant.");
  }

  const normalize = (longitude) => ((longitude - ascendant) % 360 + 360) % 360;
  const start = normalize(cusps[houseIndex]);
  let end = normalize(cusps[(houseIndex + 1) % 12]);
  if (end <= start) end += 360;
  return [start, end];
}

export function houseIndexAtRelativeAngle(angle, cusps, ascendant) {
  if (!Number.isFinite(angle)) {
    throw new TypeError("Wheel angle must be finite.");
  }

  const target = ((angle % 360) + 360) % 360;
  for (let index = 0; index < 12; index += 1) {
    const [start, end] = houseSectorInterval(index, cusps, ascendant);
    if ((target >= start && target < end) || (target + 360 >= start && target + 360 < end)) {
      return index;
    }
  }

  return 0;
}

export function houseSectorCenter(houseIndex, cusps, ascendant) {
  const [start, end] = houseSectorInterval(houseIndex, cusps, ascendant);
  return (start + end) / 2;
}