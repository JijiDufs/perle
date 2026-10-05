import { describe, expect, it } from 'vitest';
import { gradeLustre } from '../src/core/lustre';
import { OpeningEngine, type OpeningEvent } from '../src/core/opening';
import { DEFAULT_TUNING } from '../src/tuning';

const t = DEFAULT_TUNING;

/** Ouvre de `from` à `to` degrés à vitesse constante (°/s), une mesure toutes les 16 ms. */
function sweep(engine: OpeningEngine, from: number, to: number, degPerSec: number, startTime = 0): { events: OpeningEvent[]; time: number } {
  const events: OpeningEvent[] = [];
  const step = (degPerSec * 16) / 1000;
  let time = startTime;
  for (let angle = from; angle <= to; angle += step) {
    events.push(...engine.push({ angle, time }));
    time += 16;
  }
  events.push(...engine.push({ angle: to, time }));
  return { events, time };
}

/** Amène le moteur juste après le pop. */
function popped(engine: OpeningEngine): number {
  engine.push({ angle: 1, time: 0 });
  engine.push({ angle: t.popAngle, time: 100 });
  expect(engine.phase).toBe('opening');
  return 100;
}

describe("moteur d'ouverture", () => {
  it('passe en résistance dès le premier mouvement', () => {
    const engine = new OpeningEngine(t);
    engine.push({ angle: 2, time: 0 });
    expect(engine.phase).toBe('resisting');
  });

  it('se referme si on relâche pendant la résistance', () => {
    const engine = new OpeningEngine(t);
    engine.push({ angle: 3, time: 0 });
    engine.release();
    expect(engine.phase).toBe('closed');
    expect(engine.angle).toBe(0);
  });

  it('émet un pop en franchissant l’angle du pop', () => {
    const engine = new OpeningEngine(t);
    engine.push({ angle: 3, time: 0 });
    expect(engine.push({ angle: t.popAngle, time: 50 })).toEqual([{ type: 'pop' }]);
  });

  it('reste entrouverte si on relâche après le pop, sans redescendre sous le pop', () => {
    const engine = new OpeningEngine(t);
    const time = popped(engine);
    engine.push({ angle: 60, time: time + 400 });
    engine.release();
    expect(engine.phase).toBe('opening');
    engine.push({ angle: 0, time: time + 800 });
    expect(engine.angle).toBe(t.popAngle);
  });

  it('ne fêle pas une ouverture lente', () => {
    const engine = new OpeningEngine(t);
    const time = popped(engine);
    const { events } = sweep(engine, t.popAngle, 180, t.maxSafeVelocity * 0.6, time + 16);
    expect(events.some((e) => e.type === 'crack')).toBe(false);
    expect(events.at(-1)).toMatchObject({ type: 'reveal', cracked: false });
  });

  it('fêle une ouverture trop rapide dans la zone fragile, une seule fois', () => {
    const engine = new OpeningEngine(t);
    const time = popped(engine);
    const { events } = sweep(engine, t.popAngle, 180, t.maxSafeVelocity * 2, time + 16);
    expect(events.filter((e) => e.type === 'crack')).toHaveLength(1);
    expect(events.at(-1)).toMatchObject({ type: 'reveal', cracked: true });
  });

  it('ne fêle jamais une huître protégée (première du tutoriel)', () => {
    const engine = new OpeningEngine(t, true);
    const time = popped(engine);
    const { events } = sweep(engine, t.popAngle, 180, t.maxSafeVelocity * 3, time + 16);
    expect(events.some((e) => e.type === 'crack')).toBe(false);
  });

  it('ne fêle pas si on va vite après la zone fragile', () => {
    const engine = new OpeningEngine(t);
    let time = popped(engine);
    ({ time } = sweep(engine, t.popAngle, t.fragileMaxAngle + 5, t.maxSafeVelocity * 0.5, time + 16));
    engine.release();
    const { events } = sweep(engine, t.fragileMaxAngle + 5, 180, t.maxSafeVelocity * 3, time + 500);
    expect(events.some((e) => e.type === 'crack')).toBe(false);
  });

  it('ignore les mesures après la révélation', () => {
    const engine = new OpeningEngine(t);
    const time = popped(engine);
    sweep(engine, t.popAngle, 180, 100, time + 16);
    expect(engine.phase).toBe('revealed');
    expect(engine.push({ angle: 10, time: 99_999 })).toEqual([]);
  });

  it('donne un lustre S à une ouverture parfaitement régulière', () => {
    const engine = new OpeningEngine(t);
    const time = popped(engine);
    const { events } = sweep(engine, t.popAngle, 180, 150, time + 16);
    expect(events.at(-1)).toMatchObject({ type: 'reveal', lustre: 'S' });
  });
});

describe('lustre', () => {
  it('note C sans assez de mesures', () => {
    expect(gradeLustre([100, 100], t)).toBe('C');
  });

  it('note selon l’irrégularité', () => {
    expect(gradeLustre([100, 100, 100, 100], t)).toBe('S');
    expect(gradeLustre([70, 130, 70, 130], t)).toBe('A');
    expect(gradeLustre([40, 160, 40, 160], t)).toBe('B');
    expect(gradeLustre([10, 300, 0, 50], t)).toBe('C');
  });
});
