#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/display/cfb.h>
#include <zephyr/sys/printk.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/bluetooth/bluetooth.h>
#include <zephyr/bluetooth/conn.h>
#include <zephyr/bluetooth/uuid.h>
#include <zephyr/bluetooth/gatt.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <limits.h>
#include <zephyr/sys/atomic.h>
#include "logic/watch_logic.h"
#include <zephyr/drivers/uart.h>
#include <zephyr/sys/byteorder.h>

#include "services/notification_service.h"
#include "services/clock_service.h"

K_SEM_DEFINE(watch_wake, 0, 1);
K_MUTEX_DEFINE(notification_lock);
static atomic_t screen_dirty;
static char notification[NOTIF_CONTACT_STREAM_LEN + 1];
static uint16_t test_battery_mv;
static struct watch_ui ui;
static void dirty_screen(void)
{
    atomic_set(&screen_dirty, 1);
    k_sem_give(&watch_wake);
}
static uint32_t local_seconds(void) { return clock_service_get_local_seconds(); }

static const struct bt_data ad[] = {
	BT_DATA_BYTES(BT_DATA_FLAGS, (BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR)),
	BT_DATA(BT_DATA_NAME_COMPLETE, CONFIG_BT_DEVICE_NAME, sizeof(CONFIG_BT_DEVICE_NAME) - 1),
};

static const struct bt_data sd[] = {
	BT_DATA_BYTES(BT_DATA_UUID128_SOME, BT_UUID_NOTIFICATION_SERVICE_VAL),
};

static void on_notification_bar_changed(uint8_t bar_val)
{
	dirty_screen();
	printk("[SERVICE] Notification bar update: 0x%02x\n", bar_val);
}

static void on_incoming_call_received(const char *caller, uint16_t len)
{
	dirty_screen();
	k_mutex_lock(&notification_lock, K_FOREVER);
	snprintf(notification, sizeof(notification), "%.*s", len, caller);
	k_mutex_unlock(&notification_lock);
	dirty_screen();
	printk("[SERVICE] Incoming call from: %s\n", caller);
}

static void on_incoming_text_received(const char *text, uint16_t len)
{
	dirty_screen();
	k_mutex_lock(&notification_lock, K_FOREVER);
	snprintf(notification, sizeof(notification), "%.*s", len, text);
	k_mutex_unlock(&notification_lock);
	dirty_screen();
	printk("[SERVICE] Incoming text: %s\n", text);
}

static const struct notification_service_cb notif_cbs = {
	.bar_cb = on_notification_bar_changed,
	.call_cb = on_incoming_call_received,
	.text_cb = on_incoming_text_received,
};

static void on_clock_time_changed(uint32_t timestamp)
{
	dirty_screen();
	printk("[SERVICE] Clock time set to epoch: %u\n", timestamp);
}

static void on_clock_tz_changed(int16_t tz)
{
	/* Effective UTC offset already includes any DST adjustment. */
	dirty_screen();
	printk("[SERVICE] Clock timezone set to: %d\n", tz);
}

static void on_clock_timemode_changed(uint8_t mode)
{
	/* A display-format change must not reset elapsed time or the epoch base. */
	dirty_screen();
	printk("[SERVICE] Clock timemode set to: %u (%s)\n", mode, mode ? "24-hr" : "12-hr");
}

static void on_clock_dst_changed(uint8_t dst)
{
	dirty_screen();
	printk("[SERVICE] Clock DST set to: %u\n", dst);
}

static const struct clock_service_cb clock_cbs = {
	.time_cb = on_clock_time_changed,
	.tz_cb = on_clock_tz_changed,
	.timemode_cb = on_clock_timemode_changed,
	.dst_cb = on_clock_dst_changed,
};

static int draw_clock(const struct device *display, uint64_t seconds,
                      const bool pressed[3])
{
    unsigned int day_seconds = seconds % (24 * 60 * 60);
    unsigned int hour = day_seconds / 3600;
    char time_text[9];
    char label[] = "A B C";

    snprintf(time_text, sizeof(time_text), "%02u:%02u:%02u",
             (clock_service_get_timemode() ? hour : (hour % 12 ? hour % 12 : 12)), day_seconds / 60 % 60, day_seconds % 60);
    for (int i = 0; i < 3; i++) {
        if (!pressed[i]) label[i * 2] = '-';
    }
    cfb_framebuffer_clear(display, false);
    k_mutex_lock(&notification_lock, K_FOREVER);
    cfb_print(display, clock_service_get_timemode() ? "24H" : (hour < 12 ? "AM" : "PM"), 0, 0);
    if (notification[0]) cfb_print(display, notification, 24, 0);
    else if (notification_service_get_bar()) cfb_print(display, "NOTIF", 24, 0);
    k_mutex_unlock(&notification_lock);
    if (pressed[0] || pressed[1] || pressed[2]) cfb_print(display, label, 40, 0);
    cfb_print(display, clock_service_get_status() ? time_text : "Set time", 0, 16);
    return cfb_framebuffer_finalize(display);
}

#if DT_NODE_EXISTS(DT_ALIAS(watch_a))
static const struct gpio_dt_spec buttons[] = {
    GPIO_DT_SPEC_GET(DT_ALIAS(watch_a), gpios),
    GPIO_DT_SPEC_GET(DT_ALIAS(watch_b), gpios),
    GPIO_DT_SPEC_GET(DT_ALIAS(watch_c), gpios),
};
static struct gpio_callback button_callbacks[WATCH_BUTTONS];
static struct k_spinlock input_lock;
static struct { bool pending, down; int64_t at; } edges[WATCH_BUTTONS];
static void button_edge(const struct device *port, struct gpio_callback *callback, uint32_t pins)
{
    ARG_UNUSED(port); ARG_UNUSED(pins);
    unsigned i = callback - button_callbacks;
    int value = gpio_pin_get_dt(&buttons[i]);
    if (value < 0) return;
    k_spinlock_key_t key = k_spin_lock(&input_lock);
    edges[i].pending = true;
    edges[i].down = value != 0;
    edges[i].at = k_uptime_get();
    k_spin_unlock(&input_lock, key);
    k_sem_give(&watch_wake);
}
static void collect_edges(void)
{
    k_spinlock_key_t key = k_spin_lock(&input_lock);
    for (unsigned i = 0; i < WATCH_BUTTONS; ++i) {
        if (edges[i].pending) {
            watch_ui_edge(&ui, i, edges[i].down, edges[i].at);
            edges[i].pending = false;
        }
    }
    k_spin_unlock(&input_lock, key);
}
#endif

#ifdef CONFIG_F91_TEST_BRIDGE
/* Test-only transport: this does not exercise BLE radio, pairing or ATT. */
static void test_command(char *line, const bool pressed[3])
{
    unsigned long id;
    char *end;
    if (strncmp(line, "F91TEST ", 8)) return;
    id = strtoul(line + 8, &end, 10);
    if (end == line + 8 || *end != ' ' || id > UINT32_MAX) return;
    char *field = end + 1;
    char *hex = strchr(field, ' ');
    if (!hex) return;
    *hex++ = 0;
    uint8_t bytes[20];
    size_t len = !strcmp(hex, "-") ? 0 : strlen(hex) / 2;
    int err = 0;
    if (len > sizeof(bytes) || (strcmp(hex, "-") && strlen(hex) % 2)) err = -EMSGSIZE;
    for (size_t i = 0; !err && i < len; i++) {
        char pair[3] = {hex[i * 2], hex[i * 2 + 1], 0};
        if (!((pair[0] >= '0' && pair[0] <= '9') || (pair[0] >= 'a' && pair[0] <= 'f') || (pair[0] >= 'A' && pair[0] <= 'F')) ||
            !((pair[1] >= '0' && pair[1] <= '9') || (pair[1] >= 'a' && pair[1] <= 'f') || (pair[1] >= 'A' && pair[1] <= 'F'))) { err = -EINVAL; break; }
        bytes[i] = strtoul(pair, NULL, 16);
    }
    if (!err) {
        if (!strcmp(field, "ping") || !strcmp(field, "state")) {
            if (len) err = -EMSGSIZE;
            else if (!strcmp(field, "state"))
                printk("[TEST] STATE %lu buttons=%u seconds=%u mode=%u bar=%u battery_mv=%u clock_status=%u awake=%u\n", id,
                       pressed[0] | (pressed[1] << 1) | (pressed[2] << 2), local_seconds(),
                       clock_service_get_timemode(), notification_service_get_bar(), test_battery_mv, clock_service_get_status(), ui.awake);
        } else if (!strcmp(field, "battery")) {
            if (len != 2) err = -EMSGSIZE;
            else {
                uint16_t value = sys_get_le16(bytes);
                if (value < 2000 || value > 5000) err = -ERANGE;
                else test_battery_mv = value;
            }
        } else {
            err = clock_service_write(field, bytes, len, 0);
            if (err == -ENOENT) err = notification_service_write(field, bytes, len, 0);
        }
    }
    if (err) printk("[TEST] ACK %lu %s ERR %d\n", id, field, err);
    else printk("[TEST] ACK %lu %s OK\n", id, field);
}
static void poll_test_uart(const bool pressed[3])
{
    static char line[128];
    static size_t used;
    static bool overflow;
    unsigned char c;
    const struct device *uart = DEVICE_DT_GET(DT_CHOSEN(zephyr_console));
    while (!uart_poll_in(uart, &c)) {
        if (c == '\r') continue;
        if (c == '\n') {
            line[used] = 0;
            if (!overflow) test_command(line, pressed);
            else printk("[TEST] REJECT line-too-long\n");
            used = 0; overflow = false;
        } else if (used < sizeof(line) - 1) line[used++] = c;
        else overflow = true;
    }
}
#endif

int main(void)
{
    const struct device *display = DEVICE_DT_GET(DT_CHOSEN(zephyr_display));

    printk("F91 Jepler Emulation Environment Booting...\n");

    if (!device_is_ready(display)) {
        printk("Display device not ready\n");
        return 0;
    }

    if (display_set_pixel_format(display, PIXEL_FORMAT_MONO10) != 0) {
        if (display_set_pixel_format(display, PIXEL_FORMAT_MONO01) != 0) {
            printk("Failed to set required pixel format\n");
            return 0;
        }
    }

    if (cfb_framebuffer_init(display)) {
        printk("Framebuffer initialization failed!\n");
        return 0;
    }

    notification_service_init(&notif_cbs);
    clock_service_init(&clock_cbs);
    int bt_err = bt_enable(NULL);
    if (bt_err) {
        printk("Bluetooth init failed (err %d)\n", bt_err);
    } else {
        printk("Bluetooth initialized successfully\n");


        bt_err = bt_le_adv_start(BT_LE_ADV_CONN_FAST_1, ad, ARRAY_SIZE(ad), sd, ARRAY_SIZE(sd));
        if (bt_err) {
            printk("Advertising failed to start (err %d)\n", bt_err);
        } else {
            printk("BLE Advertising started (F91_Jepler)\n");
        }
    }

    bool pressed[WATCH_BUTTONS] = {false};
    watch_ui_init(&ui, k_uptime_get());
    uint32_t shown_seconds = UINT32_MAX;
    int err = display_blanking_off(display);
    if (!err) err = draw_clock(display, 0, pressed);
    if (err) { printk("Framebuffer write failed: %d\n", err); return 0; }
    printk("Watch screen ready\n");
    printk("Clock unsynchronized: Set time\n");

#if DT_NODE_EXISTS(DT_ALIAS(watch_a))
    for (unsigned i = 0; i < ARRAY_SIZE(buttons); i++) {
        if (!gpio_is_ready_dt(&buttons[i]) || gpio_pin_configure_dt(&buttons[i], GPIO_INPUT)) {
            printk("Button %c initialization failed\n", 'A' + i); return 0;
        }
        gpio_init_callback(&button_callbacks[i], button_edge, BIT(buttons[i].pin));
        if (gpio_add_callback(buttons[i].port, &button_callbacks[i]) ||
            gpio_pin_interrupt_configure_dt(&buttons[i], GPIO_INT_EDGE_BOTH)) {
            printk("Button %c interrupt initialization failed\n", 'A' + i); return 0;
        }
        button_edge(buttons[i].port, &button_callbacks[i], BIT(buttons[i].pin));
    }
#endif
#ifdef CONFIG_F91_TEST_BRIDGE
    printk("[TEST] READY v1\n");
#endif
    while (1) {
#if DT_NODE_EXISTS(DT_ALIAS(watch_a))
        collect_edges();
#endif
        int64_t now = k_uptime_get();
        struct watch_events events = watch_ui_update(&ui, now);
        for (unsigned i = 0; i < WATCH_BUTTONS; ++i) {
            pressed[i] = ui.buttons[i].pressed;
            if (events.pressed & BIT(i)) printk("Button %c pressed\n", 'A' + i);
            if (events.released & BIT(i)) printk("Button %c released (%lld ms)\n", 'A' + i,
                (long long)(now - ui.buttons[i].pressed_at));
            if (events.short_press & BIT(i)) printk("Button %c short\n", 'A' + i);
            if (events.long_press & BIT(i)) printk("Button %c long\n", 'A' + i);
        }
        if (events.short_press & BIT(2)) {
            k_mutex_lock(&notification_lock, K_FOREVER);
            notification[0] = 0;
            k_mutex_unlock(&notification_lock);
            dirty_screen();
        }
#ifdef CONFIG_F91_TEST_BRIDGE
        poll_test_uart(pressed);
#endif
        if (events.slept && !events.woke) {
            err = display_blanking_on(display);
            printk("Display asleep (%d)\n", err);
        }
        if (events.woke) {
            err = display_blanking_off(display);
            printk("Display awake (%d)\n", err);
            dirty_screen();
        }
        uint32_t seconds = local_seconds();
        bool dirty = atomic_set(&screen_dirty, 0) != 0;
        if (ui.awake && (dirty || events.pressed || events.released || seconds != shown_seconds)) {
            shown_seconds = seconds;
            err = draw_clock(display, seconds, pressed);
            if (err) printk("Framebuffer write failed: %d\n", err);
        }
        /* Only the emulator UART bridge polls. Hardware sleeps until an edge,
         * debounce/long-press deadline, display tick or BLE callback. */
        int64_t next = watch_ui_deadline(&ui);
        if (ui.awake && clock_service_get_status() && next > now + 1000) next = now + 1000;
#ifdef CONFIG_F91_TEST_BRIDGE
        if (next > now + 10) next = now + 10;
#endif
        int64_t remaining = next - k_uptime_get();
        k_sem_take(&watch_wake, next == INT64_MAX ? K_FOREVER : K_MSEC(remaining > 0 ? remaining : 0));
    }
    return 0;
}
