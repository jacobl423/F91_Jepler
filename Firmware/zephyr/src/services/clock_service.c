#include "clock_service.h"
#include <zephyr/logging/log.h>
#include <string.h>
#include <zephyr/sys/byteorder.h>
#include <errno.h>

LOG_MODULE_REGISTER(clock_service, LOG_LEVEL_INF);

static uint32_t clock_time_val;
static int16_t clock_timezone_val;
static uint8_t clock_timemode_val;
static uint8_t clock_dst_val;

static const struct clock_service_cb *app_cbs;

static ssize_t read_clock_time(struct bt_conn *conn,
			       const struct bt_gatt_attr *attr,
			       void *buf, uint16_t len,
			       uint16_t offset)
{
	return bt_gatt_attr_read(conn, attr, buf, len, offset,
				 &clock_time_val, sizeof(clock_time_val));
}

static ssize_t write_clock_time(struct bt_conn *conn,
				const struct bt_gatt_attr *attr,
				const void *buf, uint16_t len,
				uint16_t offset, uint8_t flags)
{
	int err = clock_service_write("time", buf, len, offset);
	return err ? BT_GATT_ERR(BT_ATT_ERR_VALUE_NOT_ALLOWED) : len;
}

static ssize_t read_clock_timezone(struct bt_conn *conn,
				   const struct bt_gatt_attr *attr,
				   void *buf, uint16_t len,
				   uint16_t offset)
{
	return bt_gatt_attr_read(conn, attr, buf, len, offset,
				 &clock_timezone_val, sizeof(clock_timezone_val));
}

static ssize_t write_clock_timezone(struct bt_conn *conn,
				     const struct bt_gatt_attr *attr,
				     const void *buf, uint16_t len,
				     uint16_t offset, uint8_t flags)
{
	int err = clock_service_write("timezone", buf, len, offset);
	return err ? BT_GATT_ERR(BT_ATT_ERR_VALUE_NOT_ALLOWED) : len;
}

static ssize_t read_clock_timemode(struct bt_conn *conn,
				   const struct bt_gatt_attr *attr,
				   void *buf, uint16_t len,
				   uint16_t offset)
{
	return bt_gatt_attr_read(conn, attr, buf, len, offset,
				 &clock_timemode_val, sizeof(clock_timemode_val));
}

static ssize_t write_clock_timemode(struct bt_conn *conn,
				     const struct bt_gatt_attr *attr,
				     const void *buf, uint16_t len,
				     uint16_t offset, uint8_t flags)
{
	int err = clock_service_write("timemode", buf, len, offset);
	return err ? BT_GATT_ERR(BT_ATT_ERR_VALUE_NOT_ALLOWED) : len;
}

static ssize_t read_clock_dst(struct bt_conn *conn,
			      const struct bt_gatt_attr *attr,
			      void *buf, uint16_t len,
			      uint16_t offset)
{
	return bt_gatt_attr_read(conn, attr, buf, len, offset,
				 &clock_dst_val, sizeof(clock_dst_val));
}

static ssize_t write_clock_dst(struct bt_conn *conn,
				const struct bt_gatt_attr *attr,
				const void *buf, uint16_t len,
				uint16_t offset, uint8_t flags)
{
	int err = clock_service_write("dst", buf, len, offset);
	return err ? BT_GATT_ERR(BT_ATT_ERR_VALUE_NOT_ALLOWED) : len;
}

BT_GATT_SERVICE_DEFINE(clock_svc,
	BT_GATT_PRIMARY_SERVICE(BT_UUID_CLOCK_SERVICE),
	BT_GATT_CHARACTERISTIC(BT_UUID_CLOCK_TIME_CHAR,
			       BT_GATT_CHRC_READ | BT_GATT_CHRC_WRITE,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
			       read_clock_time, write_clock_time,
			       &clock_time_val),
	BT_GATT_CHARACTERISTIC(BT_UUID_CLOCK_TIMEZONE_CHAR,
			       BT_GATT_CHRC_READ | BT_GATT_CHRC_WRITE,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
			       read_clock_timezone, write_clock_timezone,
			       &clock_timezone_val),
	BT_GATT_CHARACTERISTIC(BT_UUID_CLOCK_TIMEMODE_CHAR,
			       BT_GATT_CHRC_READ | BT_GATT_CHRC_WRITE,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
			       read_clock_timemode, write_clock_timemode,
			       &clock_timemode_val),
	BT_GATT_CHARACTERISTIC(BT_UUID_CLOCK_DST_CHAR,
			       BT_GATT_CHRC_READ | BT_GATT_CHRC_WRITE,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
			       read_clock_dst, write_clock_dst,
			       &clock_dst_val),
);

int clock_service_init(const struct clock_service_cb *cbs)
{
	app_cbs = cbs;
	clock_time_val = 0;
	clock_timezone_val = 0;
	clock_timemode_val = 0;
	clock_dst_val = 0;
	return 0;
}

uint32_t clock_service_get_time(void)
{
	return clock_time_val;
}

void clock_service_set_time(uint32_t time_sec)
{
	clock_time_val = time_sec;
}

int16_t clock_service_get_timezone(void)
{
	return clock_timezone_val;
}

void clock_service_set_timezone(int16_t tz)
{
	clock_timezone_val = tz;
}

uint8_t clock_service_get_timemode(void)
{
	return clock_timemode_val;
}

void clock_service_set_timemode(uint8_t mode)
{
	clock_timemode_val = mode;
}

uint8_t clock_service_get_dst(void)
{
	return clock_dst_val;
}

void clock_service_set_dst(uint8_t dst)
{
	clock_dst_val = dst;
}

/* Single validation path for real GATT writes and the emulator UART harness.
 * Timezone is signed minutes east of UTC; DST adds exactly 60 minutes. */
int clock_service_write(const char *field, const void *buf, uint16_t len, uint16_t offset)
{
    if (offset || !buf) return -EINVAL;
    if (!strcmp(field, "time")) {
        if (len != sizeof(uint32_t)) return -EMSGSIZE;
        uint32_t value = sys_get_le32(buf);
        clock_time_val = value;
        if (app_cbs && app_cbs->time_cb) app_cbs->time_cb(value);
        return 0;
    }
    if (!strcmp(field, "timezone")) {
        if (len != sizeof(int16_t)) return -EMSGSIZE;
        int16_t value = (int16_t)sys_get_le16(buf);
        if (value < -840 || value > 840) return -ERANGE;
        clock_timezone_val = value;
        if (app_cbs && app_cbs->tz_cb) app_cbs->tz_cb(value);
        return 0;
    }
    if (!strcmp(field, "timemode")) {
        if (len != sizeof(uint8_t)) return -EMSGSIZE;
        uint8_t value = *(const uint8_t *)buf;
        if (value > 1) return -ERANGE;
        clock_timemode_val = value;
        if (app_cbs && app_cbs->timemode_cb) app_cbs->timemode_cb(value);
        return 0;
    }
    if (!strcmp(field, "dst")) {
        if (len != sizeof(uint8_t)) return -EMSGSIZE;
        uint8_t value = *(const uint8_t *)buf;
        if (value > 1) return -ERANGE;
        clock_dst_val = value;
        if (app_cbs && app_cbs->dst_cb) app_cbs->dst_cb(value);
        return 0;
    }
    return -ENOENT;
}
