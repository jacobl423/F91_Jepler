#include "clock_service.h"
#include "logic/watch_logic.h"
#include <zephyr/kernel.h>
#include <errno.h>
#include <string.h>

static struct watch_clock clock_state;
static struct k_spinlock clock_lock;
static const struct clock_service_cb *app_cbs;

static struct watch_clock snapshot(void)
{
    k_spinlock_key_t key = k_spin_lock(&clock_lock);
    struct watch_clock value = clock_state;
    k_spin_unlock(&clock_lock, key);
    return value;
}
static ssize_t read_clock(struct bt_conn *conn, const struct bt_gatt_attr *attr,
                          void *buf, uint16_t len, uint16_t offset)
{
    uint8_t bytes[4];
    struct watch_clock value = snapshot();
    int size = watch_clock_read(&value, attr->user_data, bytes, k_uptime_get());
    return bt_gatt_attr_read(conn, attr, buf, len, offset, bytes, size);
}
static ssize_t write_clock(struct bt_conn *conn, const struct bt_gatt_attr *attr,
                           const void *buf, uint16_t len, uint16_t offset, uint8_t flags)
{
    ARG_UNUSED(conn);
    ARG_UNUSED(flags);
    if (offset) return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
    int err = clock_service_write(attr->user_data, buf, len, offset);
    if (err == -EMSGSIZE) return BT_GATT_ERR(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN);
    return err ? BT_GATT_ERR(BT_ATT_ERR_VALUE_NOT_ALLOWED) : len;
}
#define CLOCK_CHARACTERISTIC(uuid, field) \
    BT_GATT_CHARACTERISTIC(uuid, BT_GATT_CHRC_READ | BT_GATT_CHRC_WRITE, \
        BT_GATT_PERM_READ | BT_GATT_PERM_WRITE, read_clock, write_clock, field)
BT_GATT_SERVICE_DEFINE(clock_svc,
    BT_GATT_PRIMARY_SERVICE(BT_UUID_CLOCK_SERVICE),
    CLOCK_CHARACTERISTIC(BT_UUID_CLOCK_TIME_CHAR, "time"),
    CLOCK_CHARACTERISTIC(BT_UUID_CLOCK_TIMEZONE_CHAR, "timezone"),
    CLOCK_CHARACTERISTIC(BT_UUID_CLOCK_TIMEMODE_CHAR, "timemode"),
    CLOCK_CHARACTERISTIC(BT_UUID_CLOCK_DST_CHAR, "dst"),
    BT_GATT_CHARACTERISTIC(BT_UUID_CLOCK_STATUS_CHAR, BT_GATT_CHRC_READ,
        BT_GATT_PERM_READ, read_clock, NULL, "status"),
);
int clock_service_init(const struct clock_service_cb *cbs)
{
    app_cbs = cbs;
    k_spinlock_key_t key = k_spin_lock(&clock_lock);
    memset(&clock_state, 0, sizeof(clock_state));
    k_spin_unlock(&clock_lock, key);
    return 0;
}
uint32_t clock_service_get_time(void)
{
    struct watch_clock value = snapshot();
    return watch_clock_utc(&value, k_uptime_get());
}
uint32_t clock_service_get_local_seconds(void)
{
    struct watch_clock value = snapshot();
    return watch_clock_local(&value, k_uptime_get());
}
uint8_t clock_service_get_status(void) { return snapshot().valid ? 1 : 0; }
int16_t clock_service_get_timezone(void) { return snapshot().timezone; }
uint8_t clock_service_get_timemode(void) { return snapshot().mode; }
uint8_t clock_service_get_dst(void) { return snapshot().dst; }

/* One validation path for GATT and emulator. DST is metadata, never an offset. */
int clock_service_write(const char *field, const void *buf, uint16_t len, uint16_t offset)
{
    k_spinlock_key_t key = k_spin_lock(&clock_lock);
    int err = watch_clock_write(&clock_state, field, buf, len, offset, k_uptime_get());
    struct watch_clock value = clock_state;
    k_spin_unlock(&clock_lock, key);
    if (err || !app_cbs) return err;
    if (!strcmp(field, "time") && app_cbs->time_cb) app_cbs->time_cb(value.epoch);
    if (!strcmp(field, "timezone") && app_cbs->tz_cb) app_cbs->tz_cb(value.timezone);
    if (!strcmp(field, "timemode") && app_cbs->timemode_cb) app_cbs->timemode_cb(value.mode);
    if (!strcmp(field, "dst") && app_cbs->dst_cb) app_cbs->dst_cb(value.dst);
    return 0;
}
