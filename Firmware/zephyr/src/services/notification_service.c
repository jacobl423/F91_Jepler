#include "notification_service.h"
#include <zephyr/logging/log.h>
#include <string.h>

LOG_MODULE_REGISTER(notification_service, LOG_LEVEL_INF);

static uint8_t notification_bar_val;
static char incoming_call_buf[NOTIF_CONTACT_STREAM_LEN + 1];
static char incoming_text_buf[NOTIF_CONTACT_STREAM_LEN + 1];

static const struct notification_service_cb *app_cbs;

static ssize_t read_notification_bar(struct bt_conn *conn,
				    const struct bt_gatt_attr *attr,
				    void *buf, uint16_t len,
				    uint16_t offset)
{
	return bt_gatt_attr_read(conn, attr, buf, len, offset,
				 &notification_bar_val, sizeof(notification_bar_val));
}

static ssize_t write_notification_bar(struct bt_conn *conn,
				     const struct bt_gatt_attr *attr,
				     const void *buf, uint16_t len,
				     uint16_t offset, uint8_t flags)
{
	if (offset != 0 || len != sizeof(uint8_t)) {
		return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
	}

	notification_bar_val = *((const uint8_t *)buf);
	LOG_INF("Notification Bar set to: 0x%02x", notification_bar_val);

	if (app_cbs && app_cbs->bar_cb) {
		app_cbs->bar_cb(notification_bar_val);
	}

	return len;
}

static ssize_t write_incoming_call(struct bt_conn *conn,
				   const struct bt_gatt_attr *attr,
				   const void *buf, uint16_t len,
				   uint16_t offset, uint8_t flags)
{
	if (offset + len > NOTIF_CONTACT_STREAM_LEN) {
		return BT_GATT_ERR(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN);
	}

	memset(incoming_call_buf, 0, sizeof(incoming_call_buf));
	memcpy(incoming_call_buf + offset, buf, len);
	LOG_INF("Incoming Call: %s", incoming_call_buf);

	if (app_cbs && app_cbs->call_cb) {
		app_cbs->call_cb(incoming_call_buf, len);
	}

	return len;
}

static ssize_t write_incoming_text(struct bt_conn *conn,
				   const struct bt_gatt_attr *attr,
				   const void *buf, uint16_t len,
				   uint16_t offset, uint8_t flags)
{
	if (offset + len > NOTIF_CONTACT_STREAM_LEN) {
		return BT_GATT_ERR(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN);
	}

	memset(incoming_text_buf, 0, sizeof(incoming_text_buf));
	memcpy(incoming_text_buf + offset, buf, len);
	LOG_INF("Incoming Text: %s", incoming_text_buf);

	if (app_cbs && app_cbs->text_cb) {
		app_cbs->text_cb(incoming_text_buf, len);
	}

	return len;
}

BT_GATT_SERVICE_DEFINE(notification_svc,
	BT_GATT_PRIMARY_SERVICE(BT_UUID_NOTIFICATION_SERVICE),
	BT_GATT_CHARACTERISTIC(BT_UUID_NOTIFICATION_BAR_CHAR,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
			       read_notification_bar, write_notification_bar,
			       &notification_bar_val),
	BT_GATT_CHARACTERISTIC(BT_UUID_INCOMING_CALL_CHAR,
			       BT_GATT_PERM_WRITE,
			       BT_GATT_PERM_WRITE,
			       NULL, write_incoming_call,
			       incoming_call_buf),
	BT_GATT_CHARACTERISTIC(BT_UUID_INCOMING_TEXT_CHAR,
			       BT_GATT_PERM_WRITE,
			       BT_GATT_PERM_WRITE,
			       NULL, write_incoming_text,
			       incoming_text_buf),
);

int notification_service_init(const struct notification_service_cb *cbs)
{
	app_cbs = cbs;
	notification_bar_val = 0;
	memset(incoming_call_buf, 0, sizeof(incoming_call_buf));
	memset(incoming_text_buf, 0, sizeof(incoming_text_buf));
	return 0;
}

uint8_t notification_service_get_bar(void)
{
	return notification_bar_val;
}

void notification_service_set_bar(uint8_t val)
{
	notification_bar_val = val;
}
