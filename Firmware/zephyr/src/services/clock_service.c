#include "clock_service.h"
#include <zephyr/logging/log.h>
#include <string.h>

LOG_MODULE_REGISTER(clock_service, LOG_LEVEL_INF);

static uint32_t clock_time_val;
static uint16_t clock_timezone_val;
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
	if (offset != 0 || len != sizeof(uint32_t)) {
		return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
	}

	clock_time_val = *((const uint32_t *)buf);
	LOG_INF("Clock Time set to: %u", clock_time_val);

	if (app_cbs && app_cbs->time_cb) {
		app_cbs->time_cb(clock_time_val);
	}

	return len;
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
	if (offset != 0 || len != sizeof(uint16_t)) {
		return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
	}

	clock_timezone_val = *((const uint16_t *)buf);
	LOG_INF("Clock Timezone set to: %u", clock_timezone_val);

	if (app_cbs && app_cbs->tz_cb) {
		app_cbs->tz_cb(clock_timezone_val);
	}

	return len;
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
	if (offset != 0 || len != sizeof(uint8_t)) {
		return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
	}

	clock_timemode_val = *((const uint8_t *)buf);
	LOG_INF("Clock Timemode set to: %u", clock_timemode_val);

	if (app_cbs && app_cbs->timemode_cb) {
		app_cbs->timemode_cb(clock_timemode_val);
	}

	return len;
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
	if (offset != 0 || len != sizeof(uint8_t)) {
		return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
	}

	clock_dst_val = *((const uint8_t *)buf);
	LOG_INF("Clock DST set to: %u", clock_dst_val);

	if (app_cbs && app_cbs->dst_cb) {
		app_cbs->dst_cb(clock_dst_val);
	}

	return len;
}

BT_GATT_SERVICE_DEFINE(clock_svc,
	BT_GATT_PRIMARY_SERVICE(BT_UUID_CLOCK_SERVICE),
	BT_GATT_CHARACTERISTIC(BT_UUID_CLOCK_TIME_CHAR,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
			       read_clock_time, write_clock_time,
			       &clock_time_val),
	BT_GATT_CHARACTERISTIC(BT_UUID_CLOCK_TIMEZONE_CHAR,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
			       read_clock_timezone, write_clock_timezone,
			       &clock_timezone_val),
	BT_GATT_CHARACTERISTIC(BT_UUID_CLOCK_TIMEMODE_CHAR,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
			       read_clock_timemode, write_clock_timemode,
			       &clock_timemode_val),
	BT_GATT_CHARACTERISTIC(BT_UUID_CLOCK_DST_CHAR,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
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

uint16_t clock_service_get_timezone(void)
{
	return clock_timezone_val;
}

void clock_service_set_timezone(uint16_t tz)
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
