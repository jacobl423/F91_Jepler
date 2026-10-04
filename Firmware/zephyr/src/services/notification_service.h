#ifndef NOTIFICATION_SERVICE_H_
#define NOTIFICATION_SERVICE_H_

#include <zephyr/bluetooth/uuid.h>
#include <zephyr/bluetooth/gatt.h>
#include <stdint.h>

#define BT_UUID_NOTIFICATION_SERVICE_VAL \
	BT_UUID_128_ENCODE(0xfa35a2f0, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)
#define BT_UUID_NOTIFICATION_BAR_CHAR_VAL \
	BT_UUID_128_ENCODE(0xfa35a2f1, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)
#define BT_UUID_INCOMING_CALL_CHAR_VAL \
	BT_UUID_128_ENCODE(0xfa35a2f2, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)
#define BT_UUID_INCOMING_TEXT_CHAR_VAL \
	BT_UUID_128_ENCODE(0xfa35a2f3, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)

#define BT_UUID_NOTIFICATION_SERVICE BT_UUID_DECLARE_128(BT_UUID_NOTIFICATION_SERVICE_VAL)
#define BT_UUID_NOTIFICATION_BAR_CHAR BT_UUID_DECLARE_128(BT_UUID_NOTIFICATION_BAR_CHAR_VAL)
#define BT_UUID_INCOMING_CALL_CHAR BT_UUID_DECLARE_128(BT_UUID_INCOMING_CALL_CHAR_VAL)
#define BT_UUID_INCOMING_TEXT_CHAR BT_UUID_DECLARE_128(BT_UUID_INCOMING_TEXT_CHAR_VAL)

#define NOTIF_CONTACT_STREAM_LEN 20

typedef void (*notification_bar_cb_t)(uint8_t bar_val);
typedef void (*incoming_call_cb_t)(const char *caller, uint16_t len);
typedef void (*incoming_text_cb_t)(const char *text, uint16_t len);

struct notification_service_cb {
	notification_bar_cb_t bar_cb;
	incoming_call_cb_t call_cb;
	incoming_text_cb_t text_cb;
};

int notification_service_init(const struct notification_service_cb *cbs);

uint8_t notification_service_get_bar(void);
void notification_service_set_bar(uint8_t val);

#endif /* NOTIFICATION_SERVICE_H_ */
