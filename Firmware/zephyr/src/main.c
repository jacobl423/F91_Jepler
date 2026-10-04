#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/display/cfb.h>
#include <zephyr/sys/printk.h>
#include <zephyr/drivers/gpio.h>
#include <stdio.h>

static int draw_clock(const struct device *display, uint64_t seconds,
                      const bool pressed[3])
{
    unsigned int day_seconds = seconds % (24 * 60 * 60);
    unsigned int hour = day_seconds / 3600;
    char time_text[9];
    char label[] = "A B C";

    snprintf(time_text, sizeof(time_text), "%02u:%02u:%02u",
             hour % 12 ? hour % 12 : 12, day_seconds / 60 % 60, day_seconds % 60);
    for (int i = 0; i < 3; i++) {
        if (!pressed[i]) label[i * 2] = '-';
    }
    cfb_framebuffer_clear(display, false);
    cfb_print(display, hour < 12 ? "AM" : "PM", 0, 0);
    if (pressed[0] || pressed[1] || pressed[2]) cfb_print(display, label, 40, 0);
    cfb_print(display, time_text, 0, 16);
    return cfb_framebuffer_finalize(display);
}

#if DT_NODE_EXISTS(DT_ALIAS(watch_a))
static const struct gpio_dt_spec buttons[] = {
    GPIO_DT_SPEC_GET(DT_ALIAS(watch_a), gpios),
    GPIO_DT_SPEC_GET(DT_ALIAS(watch_b), gpios),
    GPIO_DT_SPEC_GET(DT_ALIAS(watch_c), gpios),
};
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

    bool pressed[3] = {false};
    /* Midnight is relative to this application boot, not the host wall clock. */
    const int64_t clock_epoch_ms = k_uptime_get();
    uint64_t shown_seconds = 0;
    int err = draw_clock(display, 0, pressed);
    if (err) {
        printk("Framebuffer write failed: %d\n", err);
        return 0;
    }
    printk("Watch screen ready\n");
    printk("Time: 12:00:00 AM\n");

#if DT_NODE_EXISTS(DT_ALIAS(watch_a))
    for (int i = 0; i < ARRAY_SIZE(buttons); i++) {
        if (!gpio_is_ready_dt(&buttons[i]) || gpio_pin_configure_dt(&buttons[i], GPIO_INPUT)) {
            printk("Button %c initialization failed\n", 'A' + i);
            return 0;
        }
    }
    int64_t press_time[3] = {0};
#endif
    while (1) {
        bool changed = false;
#if DT_NODE_EXISTS(DT_ALIAS(watch_a))
        for (int i = 0; i < ARRAY_SIZE(buttons); i++) {
            int value = gpio_pin_get_dt(&buttons[i]);
            if (value < 0 || pressed[i] == (value != 0)) {
                continue;
            }
            pressed[i] = value != 0;
            changed = true;
            if (pressed[i]) {
                press_time[i] = k_uptime_get();
                printk("Button %c pressed\n", 'A' + i);
            } else {
                printk("Button %c released (%lld ms)\n", 'A' + i,
                       (long long)(k_uptime_get() - press_time[i]));
            }
        }
#endif
        uint64_t seconds = (k_uptime_get() - clock_epoch_ms) / 1000;
        if (seconds != shown_seconds) {
            unsigned int day_seconds = seconds % (24 * 60 * 60);
            unsigned int hour = day_seconds / 3600;
            printk("Time: %02u:%02u:%02u %s\n", hour % 12 ? hour % 12 : 12,
                   day_seconds / 60 % 60, day_seconds % 60, hour < 12 ? "AM" : "PM");
        }
        if (changed || seconds != shown_seconds) {
            shown_seconds = seconds;
            err = draw_clock(display, seconds, pressed);
            if (err) printk("Framebuffer write failed: %d\n", err);
        }
        k_sleep(K_MSEC(10));
    }
    return 0;
}
