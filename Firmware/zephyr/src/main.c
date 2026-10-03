#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/display/cfb.h>
#include <zephyr/sys/printk.h>
#include <zephyr/drivers/gpio.h>

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

    cfb_framebuffer_clear(display, false);

    cfb_print(display, "f91jepler", 0, 0);
    cfb_print(display, "10:08 AM", 0, 16);

    int err = cfb_framebuffer_finalize(display);
    if (err) {
        printk("Framebuffer write failed: %d\n", err);
        return 0;
    }
    printk("Watch screen ready\n");

#if DT_NODE_EXISTS(DT_ALIAS(watch_a))
    for (int i = 0; i < ARRAY_SIZE(buttons); i++) {
        if (!gpio_is_ready_dt(&buttons[i]) || gpio_pin_configure_dt(&buttons[i], GPIO_INPUT)) {
            printk("Button %c initialization failed\n", 'A' + i);
            return 0;
        }
    }
    bool pressed[3] = {false};
    int64_t press_time[3] = {0};
#endif
    while (1) {
#if DT_NODE_EXISTS(DT_ALIAS(watch_a))
        bool changed = false;
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
        if (changed) {
            char label[] = "A B C";
            for (int i = 0; i < 3; i++) {
                if (!pressed[i]) label[i * 2] = '-';
            }
            cfb_framebuffer_clear(display, false);
            cfb_print(display, pressed[0] || pressed[1] || pressed[2] ? label : "f91jepler", 0, 0);
            cfb_print(display, "10:08 AM", 0, 16);
            err = cfb_framebuffer_finalize(display);
            if (err) printk("Framebuffer write failed: %d\n", err);
        }
#endif
        k_sleep(K_MSEC(10));
    }
    return 0;
}
