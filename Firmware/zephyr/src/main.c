#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/display/cfb.h>
#include <zephyr/sys/printk.h>

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

    cfb_framebuffer_clear(display, true);

    cfb_print(display, "f91 jepler", 0, 0);
    cfb_print(display, "10:08 AM", 0, 16);

    cfb_framebuffer_finalize(display);

    while (1) {
        k_sleep(K_SECONDS(1));
    }
    return 0;
}
