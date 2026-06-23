/** @file src/ble/advertising.c
 *  @brief BLE 广播包配置与启动实现。 */
#include "ble/advertising.h"

#include <string.h>

#include "esp_log.h"
#include "host/ble_hs.h"
#include "host/ble_store.h"

#define BLE_ADVERTISING_DIRECTED_MS 3000  ///< 优先尝试已配对手机回连的时长。

static const char *TAG = "ble_advertising";  ///< 本模块日志标签。
static const char *BLE_ADVERTISING_NAME = "Mota";  ///< 广播包内的完整设备名称。

/**
 * @brief 读取一个已配对手机地址，用于定向广播回连。
 * @param peer_addr 写入已配对手机地址的输出缓冲区。
 * @return 找到已配对手机返回 true。
 */
static bool ble_advertising_get_bonded_peer(ble_addr_t *peer_addr)
{
    int peer_count = 1;  ///< 只取一个已配对手机用于定向广播。
    int rc = ble_store_util_bonded_peers(peer_addr, &peer_count, 1);

    return rc == 0 && peer_count > 0;
}

/**
 * @brief 启动底层 GAP 广播过程。
 * @param own_addr_type NimBLE 推断出的本机地址类型。
 * @param direct_addr 非空时启动定向广播，空指针时启动普通广播。
 * @param duration_ms 广播持续时间，普通广播可传 BLE_HS_FOREVER。
 * @param gap_event_cb GAP 事件回调。
 * @return NimBLE 返回码，0 表示成功。
 */
static int ble_advertising_start_gap(uint8_t own_addr_type,
                                     const ble_addr_t *direct_addr,
                                     int32_t duration_ms,
                                     ble_gap_event_fn *gap_event_cb)
{
    struct ble_gap_adv_params advertising_params;  ///< 可连接广播的 GAP 参数。

    memset(&advertising_params, 0, sizeof(advertising_params));
    if (direct_addr != NULL) {
        advertising_params.conn_mode = BLE_GAP_CONN_MODE_DIR;
        advertising_params.disc_mode = BLE_GAP_DISC_MODE_NON;
        advertising_params.high_duty_cycle = 1;
    } else {
        advertising_params.conn_mode = BLE_GAP_CONN_MODE_UND;
        advertising_params.disc_mode = BLE_GAP_DISC_MODE_GEN;
    }

    return ble_gap_adv_start(own_addr_type, direct_addr, duration_ms,
                             &advertising_params, gap_event_cb, NULL);
}

int ble_advertising_start(uint8_t own_addr_type,
                          const ble_uuid128_t *service_uuid,
                          ble_gap_event_fn *gap_event_cb,
                          bool prefer_bonded_peer)
{
    struct ble_hs_adv_fields fields;  ///< Legacy advertising payload 字段集合。
    ble_addr_t bonded_peer;           ///< 最近一次用于定向广播的已配对地址。
    int rc;                           ///< NimBLE API 返回码。

    memset(&fields, 0, sizeof(fields));
    fields.flags = BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP;
    fields.name = (uint8_t *)BLE_ADVERTISING_NAME;
    fields.name_len = strlen(BLE_ADVERTISING_NAME);
    fields.name_is_complete = 1;
    fields.uuids128 = (ble_uuid128_t[]){ *service_uuid };
    fields.num_uuids128 = 1;
    fields.uuids128_is_complete = 1;

    rc = ble_gap_adv_set_fields(&fields);
    if (rc != 0) {
        ESP_LOGE(TAG, "failed to set advertising fields: %d", rc);
        return rc;
    }

    if (prefer_bonded_peer &&
        ble_advertising_get_bonded_peer(&bonded_peer)) {
        rc = ble_advertising_start_gap(own_addr_type, &bonded_peer,
                                       BLE_ADVERTISING_DIRECTED_MS,
                                       gap_event_cb);
        if (rc == 0) {
            ESP_LOGD(TAG, "started directed advertising");
            return 0;
        }

        ESP_LOGW(TAG, "failed to start directed advertising: %d", rc);
    }

    rc = ble_advertising_start_gap(own_addr_type, NULL, BLE_HS_FOREVER,
                                   gap_event_cb);
    if (rc != 0) {
        ESP_LOGE(TAG, "failed to start advertising: %d", rc);
    }

    return rc;
}
