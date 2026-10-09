#ifndef CLOCK_SERVICE_H_
#define CLOCK_SERVICE_H_

#include <zephyr/bluetooth/uuid.h>
#include <zephyr/bluetooth/gatt.h>
#include <stdint.h>

#define BT_UUID_CLOCK_SERVICE_VAL \
	BT_UUID_128_ENCODE(0xfa35b2f0, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)
#define BT_UUID_CLOCK_TIME_CHAR_VAL \
	BT_UUID_128_ENCODE(0xfa35b2f1, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)
#define BT_UUID_CLOCK_TIMEZONE_CHAR_VAL \
	BT_UUID_128_ENCODE(0xfa35b2f2, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)
#define BT_UUID_CLOCK_TIMEMODE_CHAR_VAL \
	BT_UUID_128_ENCODE(0xfa35b2f3, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)
#define BT_UUID_CLOCK_DST_CHAR_VAL \
	BT_UUID_128_ENCODE(0xfa35b2f4, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)

#define BT_UUID_CLOCK_STATUS_CHAR_VAL \
	BT_UUID_128_ENCODE(0xfa35b2f5, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)

#define BT_UUID_CLOCK_SERVICE BT_UUID_DECLARE_128(BT_UUID_CLOCK_SERVICE_VAL)
#define BT_UUID_CLOCK_TIME_CHAR BT_UUID_DECLARE_128(BT_UUID_CLOCK_TIME_CHAR_VAL)
#define BT_UUID_CLOCK_TIMEZONE_CHAR BT_UUID_DECLARE_128(BT_UUID_CLOCK_TIMEZONE_CHAR_VAL)
#define BT_UUID_CLOCK_TIMEMODE_CHAR BT_UUID_DECLARE_128(BT_UUID_CLOCK_TIMEMODE_CHAR_VAL)
#define BT_UUID_CLOCK_DST_CHAR BT_UUID_DECLARE_128(BT_UUID_CLOCK_DST_CHAR_VAL)

#define BT_UUID_CLOCK_STATUS_CHAR BT_UUID_DECLARE_128(BT_UUID_CLOCK_STATUS_CHAR_VAL)

typedef void (*clock_time_write_cb_t)(uint32_t timestamp);
typedef void (*clock_timezone_write_cb_t)(int16_t tz);
typedef void (*clock_timemode_write_cb_t)(uint8_t mode);
typedef void (*clock_dst_write_cb_t)(uint8_t dst);

struct clock_service_cb {
	clock_time_write_cb_t time_cb;
	clock_timezone_write_cb_t tz_cb;
	clock_timemode_write_cb_t timemode_cb;
	clock_dst_write_cb_t dst_cb;
};

int clock_service_init(const struct clock_service_cb *cbs);

uint32_t clock_service_get_time(void);
uint32_t clock_service_get_local_seconds(void);
uint8_t clock_service_get_status(void);


int16_t clock_service_get_timezone(void);


uint8_t clock_service_get_timemode(void);


uint8_t clock_service_get_dst(void);


int clock_service_write(const char *field, const void *buf, uint16_t len, uint16_t offset);

#endif /* CLOCK_SERVICE_H_ */
