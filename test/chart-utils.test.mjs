import assert from "node:assert/strict";
import test from "node:test";
import { Ayanamsa, Body, createEphemera, HouseSystem } from "@astrologer/ephemera";
import {
  daysInMonth,
  houseIndexAtRelativeAngle,
  houseSectorCenter,
  localDateTimeToUtcParts,
  normalizeBirth,
  normalizeStoredState,
  wholeSignCusps
} from "../src/chart-utils.mjs";

const defaultBirth = {
  y: 1998,
  m: 8,
  d: 27,
  t: "05:00",
  name: "",
  utcOffset: -5,
  latitude: 40.8448,
  longitude: -73.8648,
  houseSystem: "placidus",
  zodiacMode: "tropical"
};

test("Gregorian month lengths respect leap-century rules", () => {
  assert.equal(daysInMonth(2000, 2), 29);
  assert.equal(daysInMonth(1900, 2), 28);
  assert.equal(daysInMonth(1998, 2), 28);
  assert.equal(daysInMonth(2024, 2), 29);
  assert.equal(daysInMonth(2024, 13), 0);
});

test("local time conversion preserves years 1 through 99", () => {
  assert.deepEqual(localDateTimeToUtcParts(1, 1, 1, "12:30", 0), {
    year: 1,
    month: 1,
    day: 1,
    hour: 12,
    minute: 30
  });
  assert.deepEqual(localDateTimeToUtcParts(99, 12, 31, "23:30", 0), {
    year: 99,
    month: 12,
    day: 31,
    hour: 23,
    minute: 30
  });
});

test("local UTC offsets correctly roll across days and years", () => {
  assert.deepEqual(localDateTimeToUtcParts(1998, 8, 27, "05:00", -4), {
    year: 1998,
    month: 8,
    day: 27,
    hour: 9,
    minute: 0
  });
  assert.deepEqual(localDateTimeToUtcParts(1998, 8, 27, "05:00", 10), {
    year: 1998,
    month: 8,
    day: 26,
    hour: 19,
    minute: 0
  });
  assert.deepEqual(localDateTimeToUtcParts(2020, 1, 1, "00:00", 14), {
    year: 2019,
    month: 12,
    day: 31,
    hour: 10,
    minute: 0
  });
});

test("birth normalization accepts complete and legacy saved records", () => {
  assert.deepEqual(normalizeBirth(defaultBirth), defaultBirth);
  assert.deepEqual(
    normalizeBirth({ y: "1998", m: "8", d: "27", t: "05:00" }, defaultBirth),
    defaultBirth
  );
  assert.deepEqual(normalizeBirth({ ...defaultBirth, name: "  Avery  " }).name, "Avery");
});

test("birth normalization rejects impossible dates and unsupported chart inputs", () => {
  assert.throws(() => normalizeBirth({ ...defaultBirth, d: 29, y: 1499 }), /between 1550 and 2650/);
  assert.throws(() => normalizeBirth({ ...defaultBirth, d: 29, y: 1998, m: 2 }), /day is not valid/);
  assert.throws(() => normalizeBirth({ ...defaultBirth, t: "24:00" }), /HH:MM/);
  assert.throws(() => normalizeBirth({ ...defaultBirth, latitude: 91 }), /Latitude/);
  assert.throws(() => normalizeBirth({ ...defaultBirth, longitude: -181 }), /Longitude/);
  assert.throws(() => localDateTimeToUtcParts(1998, 8, 27, "05:00", 15), /UTC offset/);
  assert.throws(() => normalizeBirth({ ...defaultBirth, houseSystem: "unknown" }), /Placidus or Whole Sign houses/);
  assert.throws(() => normalizeBirth(null), /object/);
});

test("malformed localStorage shapes restore as safe empty state", () => {
  assert.deepEqual(normalizeStoredState(null), { birth: null, visited: [], notes: {}, noteDates: {} });
  assert.deepEqual(normalizeStoredState("not-json-object"), { birth: null, visited: [], notes: {}, noteDates: {} });
  assert.deepEqual(normalizeStoredState({ birth: [], visited: "1,2", notes: [], noteDates: null }), {
    birth: null,
    visited: [],
    notes: {},
    noteDates: {}
  });
  assert.deepEqual(normalizeStoredState({ visited: [-1, 0, 11, 12, 1.5, "2"] }).visited, [0, 11]);
});

test("Whole Sign cusps start at zero degrees of the Ascendant's sign", () => {
  assert.deepEqual(wholeSignCusps(149.6775), [120, 150, 180, 210, 240, 270, 300, 330, 0, 30, 60, 90]);
  assert.deepEqual(wholeSignCusps(359.99), [330, 0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300]);
});

test("house intervals wrap around zero and assign exact cusps to the next house", () => {
  const cusps = [350, 20, 50, 80, 110, 140, 170, 200, 230, 260, 290, 320];
  const ascendant = 355;
  assert.equal(houseIndexAtRelativeAngle(359, cusps, ascendant), 0);
  assert.equal(houseIndexAtRelativeAngle(0, cusps, ascendant), 0);
  assert.equal(houseIndexAtRelativeAngle(24.999, cusps, ascendant), 0);
  assert.equal(houseIndexAtRelativeAngle(25, cusps, ascendant), 1);
  assert.equal(houseIndexAtRelativeAngle(55, cusps, ascendant), 2);
  assert.equal(houseSectorCenter(0, cusps, ascendant), 370);
  assert.throws(() => houseIndexAtRelativeAngle(0, [...cusps.slice(0, 11), NaN], ascendant), /12 cusps/);
});

test("Whole Sign chart places tropical Virgo Sun in house 2 and sidereal Leo Sun in house 1", async (t) => {
  const ephemeris = await createEphemera();
  t.after(() => ephemeris.close?.());

  const utc = localDateTimeToUtcParts(1998, 8, 27, "05:00", -5);
  const julian = ephemeris.utcToJd(utc.year, utc.month, utc.day, utc.hour, utc.minute);
  assert.ok(julian);
  const houseInfo = ephemeris.housesInfo(julian.jdUt, defaultBirth.longitude, defaultBirth.latitude, HouseSystem.WholeSign);
  assert.ok(houseInfo);
  const tropicalSun = ephemeris.position(Body.Sun, julian.jdUt, { year: 1998 });
  const ayanamsa = ephemeris.ayanamsa(Ayanamsa.Lahiri, julian.jdTt);
  const siderealSunLongitude = (tropicalSun.longitude - ayanamsa + 360) % 360;
  const ascendant = ephemeris.houseAngles(julian.jdUt, defaultBirth.longitude, defaultBirth.latitude).ascendant;
  const cusps = wholeSignCusps(ascendant);

  assert.equal(ephemeris.splitLongitude(tropicalSun.longitude).sign, 5);
  assert.equal(Math.floor(ephemeris.housePosition(houseInfo.cusps, tropicalSun.longitude)) - 1, 1);
  assert.equal(ephemeris.splitLongitude(siderealSunLongitude).sign, 4);
  assert.equal(Math.floor(ephemeris.housePosition(cusps, siderealSunLongitude)) - 1, 0);
});
