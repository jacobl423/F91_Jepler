#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>

int main(void)
{
    printk("F91 Jepler Emulation Environment Booting...\n");

    while (1) {
        k_sleep(K_SECONDS(1));
        printk("Watch heartbeat...\n");
    }
    return 0;
}
