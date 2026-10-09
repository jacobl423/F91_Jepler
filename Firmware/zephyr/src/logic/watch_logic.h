#ifndef F91_WATCH_LOGIC_H
#define F91_WATCH_LOGIC_H
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* Wire epoch is uint32 seconds; offset is effective minutes east of UTC. */
struct watch_clock {
    uint32_t epoch;
    int64_t set_at_ms;
    int16_t timezone;
    uint8_t mode, dst;
    bool valid;
};
uint32_t watch_clock_utc(const struct watch_clock *clock, int64_t now);
uint32_t watch_clock_local(const struct watch_clock *clock, int64_t now);
int watch_clock_write(struct watch_clock *clock, const char *field,
                      const uint8_t *data, size_t length, uint16_t offset, int64_t now);
/* Encodes a snapshot; returns byte count or negative errno. */
int watch_clock_read(const struct watch_clock *clock, const char *field,
                     uint8_t *data, int64_t now);

#define WATCH_BUTTONS 3
#define WATCH_DEBOUNCE_MS 30
#define WATCH_LONG_MS 800
#define WATCH_DISPLAY_MS 10000
struct watch_button {
    bool raw, pressed, long_sent, consumed;
    int64_t raw_since, pressed_at;
};
struct watch_ui {
    struct watch_button buttons[WATCH_BUTTONS];
    bool awake;
    int64_t sleep_at;
};
struct watch_events {
    uint8_t pressed, released, short_press, long_press;
    bool woke, slept;
};
void watch_ui_init(struct watch_ui *ui, int64_t now);
/* Feed each physical edge, including bounce ending at the previous level. */
void watch_ui_edge(struct watch_ui *ui, unsigned button, bool down, int64_t at);
struct watch_events watch_ui_update(struct watch_ui *ui, int64_t now);
int64_t watch_ui_deadline(const struct watch_ui *ui);
#endif
