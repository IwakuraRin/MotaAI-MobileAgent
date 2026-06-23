/** @file include/ble/advertising.h
 *  @brief BLE 广播包配置与启动接口定义。
 */
#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "host/ble_uuid.h"

struct ble_gap_event;  ///< NimBLE GAP 事件对象。
typedef int ble_gap_event_fn(struct ble_gap_event *event, void *arg);  ///< NimBLE GAP 事件回调函数类型。

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief 设置广播字段并启动可连接广播。
 * @param own_addr_type NimBLE 推断出的本机地址类型。
 * @param service_uuid 要放入广播包的主服务 UUID。
 * @param gap_event_cb GAP 事件回调。
 * @param prefer_bonded_peer 是否优先尝试已配对手机的定向广播。
 * @return NimBLE 返回码，0 表示成功。
 */
int ble_advertising_start(uint8_t own_addr_type,
                          const ble_uuid128_t *service_uuid,
                          ble_gap_event_fn *gap_event_cb,
                          bool prefer_bonded_peer);

#ifdef __cplusplus
}
#endif
