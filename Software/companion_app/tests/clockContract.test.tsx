import { afterEach, describe, expect, it, vi } from 'vitest';
import { render, screen, cleanup } from '@testing-library/react';
import vectors from '../../../protocol/clock-vectors.json';
import { MockBleService } from '../src/ble/mockBleService';
import { CLOCK_SERVICE_UUID, CLOCK_TIME_CHAR_UUID, CLOCK_TIMEZONE_CHAR_UUID, CLOCK_TIMEMODE_CHAR_UUID, CLOCK_DST_CHAR_UUID, CLOCK_STATUS_CHAR_UUID } from '../src/ble/gattConstants';
import { deserializeTime } from '../src/ble/gattSerializer';
import { syncClock } from '../src/state/syncService';
import MockWatchPreview from '../src/components/MockWatchPreview';
const id = 'F91-WATCH-SIM-01';
const fields = { time: CLOCK_TIME_CHAR_UUID, timezone: CLOCK_TIMEZONE_CHAR_UUID, timemode: CLOCK_TIMEMODE_CHAR_UUID, dst: CLOCK_DST_CHAR_UUID };
async function connected() { const mock = new MockBleService(); await mock.connect(id); return mock; }
afterEach(() => { vi.restoreAllMocks(); cleanup(); });
describe('shared firmware/companion clock contract', () => {
  for (const v of vectors.cases) it(v.name, async () => {
    let now = 0;
    vi.spyOn(performance, 'now').mockImplementation(() => now);
    const mock = await connected();
    await syncClock(id, mock, { date: new Date(v.utc * 1000), timezoneOffsetMinutes: v.offsetMinutes, isDst: Boolean(v.dst) });
    const writes = mock.getWriteHistory();
    expect([...writes[0].data]).toEqual(v.timeBytes);
    expect([...writes[1].data]).toEqual(v.timezoneBytes);
    now = v.elapsedSeconds * 1000;
    expect(deserializeTime(await mock.readCharacteristic(id, CLOCK_SERVICE_UUID, CLOCK_TIME_CHAR_UUID))).toBe(v.expectedUtc);
    const state = mock.getWatchState();
    expect((state.clockTime + state.clockTimezone * 60) % 86400).toBe(v.expectedLocalSeconds);
  });
  for (const v of vectors.invalidWrites) it(`rejects invalid ${v.field} ${v.bytes}`, async () => {
    const mock = await connected();
    await expect(mock.writeCharacteristic(id, CLOCK_SERVICE_UUID, fields[v.field as keyof typeof fields], new Uint8Array(v.bytes))).rejects.toThrow(/GATT Error/);
    expect(await mock.readCharacteristic(id, CLOCK_SERVICE_UUID, CLOCK_STATUS_CHAR_UUID)).toEqual(new Uint8Array([0]));
    expect(mock.getWriteHistory()).toHaveLength(0);
  });
  it('starts with Set time and becomes valid only on successful time write, including epoch zero', async () => {
    const mock = await connected();
    render(<MockWatchPreview bleClient={mock} status="CONNECTED" />);
    expect(screen.getByTestId('watch-time-display').textContent).toBe('Set time');
    await mock.writeCharacteristic(id, CLOCK_SERVICE_UUID, CLOCK_TIMEZONE_CHAR_UUID, new Uint8Array([0, 0]));
    expect(mock.getWatchState().clockValid).toBe(false);
    await mock.writeCharacteristic(id, CLOCK_SERVICE_UUID, CLOCK_TIME_CHAR_UUID, new Uint8Array(4));
    expect(await mock.readCharacteristic(id, CLOCK_SERVICE_UUID, CLOCK_STATUS_CHAR_UUID)).toEqual(new Uint8Array([1]));
    await expect(mock.writeCharacteristic(id, CLOCK_SERVICE_UUID, CLOCK_STATUS_CHAR_UUID, new Uint8Array([0]))).rejects.toThrow();
    mock.reset(); expect(mock.getWatchState().clockValid).toBe(false);
  });
  it('blocks old firmware before writing any clock fields', async () => {
    const mock = await connected();
    vi.spyOn(mock, 'readCharacteristic').mockRejectedValue(new Error('Characteristic not found'));
    await expect(syncClock(id, mock)).rejects.toThrow(/firmware update required/);
    expect(mock.getWriteHistory()).toHaveLength(0);
  });
  it('does not misdiagnose a transport failure as old firmware', async () => {
    const mock = await connected();
    vi.spyOn(mock, 'readCharacteristic').mockRejectedValue(new Error('Permission denied'));
    await expect(syncClock(id, mock)).rejects.toThrow(/Could not verify clock compatibility/);
    expect(mock.getWriteHistory()).toHaveLength(0);
  });
  for (const [index, uuid] of Object.values(fields).entries()) it(`reports ${index} acknowledged writes and retries all fields`, async () => {
    const mock = await connected(); mock.failNextWrite(uuid);
    await expect(syncClock(id, mock)).rejects.toMatchObject({ stepsCompleted: index });
    expect(mock.getWriteHistory()).toHaveLength(index);
    mock.clearWriteHistory(); await syncClock(id, mock);
    expect(mock.getWriteHistory().map(w => w.characteristicUuid)).toEqual(Object.values(fields));
  });
});
