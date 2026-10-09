#include "watch_logic.h"
#include <errno.h>
#include <limits.h>
#include <string.h>

uint32_t watch_clock_utc(const struct watch_clock *clock, int64_t now)
{
    if (!clock->valid) return 0;
    uint64_t elapsed = now > clock->set_at_ms ? (uint64_t)(now - clock->set_at_ms) / 1000 : 0;
    uint64_t utc = clock->epoch + elapsed;
    return utc > UINT32_MAX ? UINT32_MAX : (uint32_t)utc;
}
uint32_t watch_clock_local(const struct watch_clock *clock, int64_t now)
{
    int64_t seconds = watch_clock_utc(clock, now) + (int64_t)clock->timezone * 60;
    return (uint32_t)((seconds % 86400 + 86400) % 86400);
}
int watch_clock_write(struct watch_clock *clock, const char *field,
                      const uint8_t *data, size_t length, uint16_t offset, int64_t now)
{
    if (offset) return -EINVAL;
    if (!strcmp(field, "time")) {
        if (length != 4) return -EMSGSIZE;
        if (!data) return -EINVAL;
        clock->epoch = (uint32_t)data[0] | (uint32_t)data[1] << 8 |
                       (uint32_t)data[2] << 16 | (uint32_t)data[3] << 24;
        clock->set_at_ms = now;
        clock->valid = true;
    } else if (!strcmp(field, "timezone")) {
        if (length != 2) return -EMSGSIZE;
        if (!data) return -EINVAL;
        int16_t value = (int16_t)((uint16_t)data[0] | (uint16_t)data[1] << 8);
        if (value < -840 || value > 840) return -ERANGE;
        clock->timezone = value;
    } else if (!strcmp(field, "timemode") || !strcmp(field, "dst")) {
        if (length != 1) return -EMSGSIZE;
        if (!data) return -EINVAL;
        if (*data > 1) return -ERANGE;
        if (!strcmp(field, "dst")) clock->dst = *data;
        else clock->mode = *data;
    } else return -ENOENT;
    return 0;
}
int watch_clock_read(const struct watch_clock *clock, const char *field,
                     uint8_t *data, int64_t now)
{
    uint32_t value;
    int length;
    if (!strcmp(field, "time")) { value = watch_clock_utc(clock, now); length = 4; }
    else if (!strcmp(field, "timezone")) { value = (uint16_t)clock->timezone; length = 2; }
    else if (!strcmp(field, "timemode")) { value = clock->mode; length = 1; }
    else if (!strcmp(field, "dst")) { value = clock->dst; length = 1; }
    else if (!strcmp(field, "status")) { value = clock->valid ? 1 : 0; length = 1; }
    else return -ENOENT;
    for (int i = 0; i < length; ++i) data[i] = (uint8_t)(value >> (8 * i));
    return length;
}
void watch_ui_init(struct watch_ui *ui, int64_t now)
{
    memset(ui, 0, sizeof(*ui));
    ui->awake = true; /* Initial Set time / boot screen. */
    ui->sleep_at = now + WATCH_DISPLAY_MS;
}
void watch_ui_edge(struct watch_ui *ui, unsigned button, bool down, int64_t at)
{
    if (button >= WATCH_BUTTONS) return;
    ui->buttons[button].raw = down;
    ui->buttons[button].raw_since = at;
}
struct watch_events watch_ui_update(struct watch_ui *ui, int64_t now)
{
    struct watch_events events = {0};
    /* Expiry precedes edges so a press at the boundary is a consumed wake. */
    if (ui->awake && now >= ui->sleep_at) { ui->awake = false; events.slept = true; }
    for (unsigned i = 0; i < WATCH_BUTTONS; ++i) {
        struct watch_button *button = &ui->buttons[i];
        uint8_t bit = (uint8_t)(1u << i);
        if (button->raw != button->pressed && now - button->raw_since >= WATCH_DEBOUNCE_MS) {
            button->pressed = button->raw;
            if (button->pressed) {
                button->pressed_at = button->raw_since + WATCH_DEBOUNCE_MS;
                button->long_sent = false;
                events.pressed |= bit;
                if (!ui->awake) {
                    ui->awake = true; events.woke = true;
                    /* Consume all buttons participating in the wake gesture. */
                    for (unsigned j = 0; j < WATCH_BUTTONS; ++j)
                        if (ui->buttons[j].raw || ui->buttons[j].pressed) ui->buttons[j].consumed = true;
                }
                ui->sleep_at = now + WATCH_DISPLAY_MS;
            } else {
                events.released |= bit;
                if (!button->consumed && !button->long_sent) events.short_press |= bit;
                button->consumed = false;
                if (ui->awake) ui->sleep_at = now + WATCH_DISPLAY_MS;
            }
        }
        if (button->pressed && button->raw && !button->long_sent &&
            now - button->pressed_at >= WATCH_LONG_MS) {
            button->long_sent = true;
            if (!button->consumed) events.long_press |= bit;
            if (ui->awake) ui->sleep_at = now + WATCH_DISPLAY_MS;
        }
    }
    return events;
}
int64_t watch_ui_deadline(const struct watch_ui *ui)
{
    int64_t next = ui->awake ? ui->sleep_at : INT64_MAX;
    for (unsigned i = 0; i < WATCH_BUTTONS; ++i) {
        const struct watch_button *button = &ui->buttons[i];
        int64_t at = INT64_MAX;
        if (button->raw != button->pressed) at = button->raw_since + WATCH_DEBOUNCE_MS;
        else if (button->pressed && !button->long_sent) at = button->pressed_at + WATCH_LONG_MS;
        if (at < next) next = at;
    }
    return next;
}
