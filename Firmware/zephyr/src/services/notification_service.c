#include "notification_service.h"
#include <zephyr/logging/log.h>
#include <string.h>
#include <errno.h>

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
	int err = notification_service_write("bar", buf, len, offset);
	return err ? BT_GATT_ERR(BT_ATT_ERR_VALUE_NOT_ALLOWED) : len;
}

static ssize_t write_incoming_call(struct bt_conn *conn,
				   const struct bt_gatt_attr *attr,
				   const void *buf, uint16_t len,
				   uint16_t offset, uint8_t flags)
{
	int err = notification_service_write("call", buf, len, offset);
	return err ? BT_GATT_ERR(BT_ATT_ERR_VALUE_NOT_ALLOWED) : len;
}

static ssize_t write_incoming_text(struct bt_conn *conn,
				   const struct bt_gatt_attr *attr,
				   const void *buf, uint16_t len,
				   uint16_t offset, uint8_t flags)
{
	int err = notification_service_write("text", buf, len, offset);
	return err ? BT_GATT_ERR(BT_ATT_ERR_VALUE_NOT_ALLOWED) : len;
}

BT_GATT_SERVICE_DEFINE(notification_svc,
	BT_GATT_PRIMARY_SERVICE(BT_UUID_NOTIFICATION_SERVICE),
	BT_GATT_CHARACTERISTIC(BT_UUID_NOTIFICATION_BAR_CHAR,
			       BT_GATT_CHRC_READ | BT_GATT_CHRC_WRITE,
			       BT_GATT_PERM_READ | BT_GATT_PERM_WRITE,
			       read_notification_bar, write_notification_bar,
			       &notification_bar_val),
	BT_GATT_CHARACTERISTIC(BT_UUID_INCOMING_CALL_CHAR,
			       BT_GATT_CHRC_WRITE,
			       BT_GATT_PERM_WRITE,
			       NULL, write_incoming_call,
			       incoming_call_buf),
	BT_GATT_CHARACTERISTIC(BT_UUID_INCOMING_TEXT_CHAR,
			       BT_GATT_CHRC_WRITE,
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

int notification_service_write(const char *field, const void *buf, uint16_t len, uint16_t offset)
{
    if (offset || !buf) return -EINVAL;
    if (!strcmp(field, "bar")) {
        if (len != 1) return -EMSGSIZE;
        notification_bar_val = *(const uint8_t *)buf;
        if (app_cbs && app_cbs->bar_cb) app_cbs->bar_cb(notification_bar_val);
        return 0;
    }
    bool call = !strcmp(field, "call");
    if (!call && strcmp(field, "text")) return -ENOENT;
    if (!len || len > NOTIF_CONTACT_STREAM_LEN) return -EMSGSIZE;
    if (memchr(buf, 0, len)) return -EINVAL;
    char *dest = call ? incoming_call_buf : incoming_text_buf;
    memcpy(dest, buf, len);
    dest[len] = 0;
    if (app_cbs) {
        if (call && app_cbs->call_cb) app_cbs->call_cb(dest, len);
        if (!call && app_cbs->text_cb) app_cbs->text_cb(dest, len);
    }
    return 0;
}
