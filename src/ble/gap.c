/** @file src/ble/gap.c
 *  @brief BLE GAP 生命周期管理实现。 */
#include "ble/gap.h"

#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "ble/advertising.h"
#include "ble/gatt.h"
#include "ble/stream.h"
#include "esp_log.h"
#include "host/ble_gap.h"
#include "host/ble_hs.h"
#include "host/ble_sm.h"
#include "host/ble_store.h"

static const char *TAG = "ble_gap";  ///< 本模块日志标签。
static uint8_t own_addr_type;  ///< NimBLE 推断出的本机 BLE 地址类型。
static bool prefer_bonded_peer;  ///< 下一轮广播是否优先尝试已配对手机。

static void ble_gap_advertise(void);

/**
 * @brief 将 NimBLE 地址格式化为日志文本。
 * @param addr 要格式化的 BLE 地址。
 * @param buffer 输出字符串缓冲区。
 * @param buffer_len 输出字符串缓冲区长度。
 */
static void ble_gap_format_addr(const ble_addr_t *addr, char *buffer,
                                size_t buffer_len)
{
    const uint8_t *value = addr->val;  ///< NimBLE 使用小端顺序保存地址字节。

    snprintf(buffer, buffer_len, "%u:%02x:%02x:%02x:%02x:%02x:%02x",
             addr->type, value[5], value[4], value[3], value[2], value[1],
             value[0]);
}

/**
 * @brief 打印连接描述中的地址、安全状态和连接参数。
 * @param label 日志前缀，用于标识打印场景。
 * @param desc NimBLE 连接描述。
 */
static void ble_gap_log_conn_desc(const char *label,
                                  const struct ble_gap_conn_desc *desc)
{
    char peer_id[24];   ///< 对端 identity 地址字符串。
    char peer_ota[24];  ///< 对端空口地址字符串。

    ble_gap_format_addr(&desc->peer_id_addr, peer_id, sizeof(peer_id));
    ble_gap_format_addr(&desc->peer_ota_addr, peer_ota, sizeof(peer_ota));
    ESP_LOGD(TAG,
             "%s: handle=%u peer_id=%s peer_ota=%s bonded=%u encrypted=%u authenticated=%u authorized=%u key_size=%u itvl=%u latency=%u timeout=%u role=%u",
             label, desc->conn_handle, peer_id, peer_ota,
             desc->sec_state.bonded, desc->sec_state.encrypted,
             desc->sec_state.authenticated, desc->sec_state.authorize,
             desc->sec_state.key_size, desc->conn_itvl, desc->conn_latency,
             desc->supervision_timeout, desc->role);
}

/** @brief 处理连接、断开、配对和广播完成事件。 */
static int ble_gap_event(struct ble_gap_event *event, void *arg)
{
    struct ble_gap_conn_desc desc;  ///< 当前连接描述，用于安全事件处理。
    struct ble_sm_io sm_io;         ///< 配对输入输出响应。
    int rc;                         ///< NimBLE API 返回码。

    (void)arg;

    ble_stream_on_gap_event(event);

    switch (event->type) {
    case BLE_GAP_EVENT_CONNECT:
        if (event->connect.status != 0) {
            ESP_LOGW(TAG, "connection failed: %d", event->connect.status);
            ble_gap_advertise();
        } else {
            ESP_LOGD(TAG, "connected: handle=%u",
                     event->connect.conn_handle);
            rc = ble_gap_conn_find(event->connect.conn_handle, &desc);
            if (rc == 0) {
                ble_gap_log_conn_desc("connection", &desc);
            } else {
                ESP_LOGW(TAG, "failed to find connection after connect: %d",
                         rc);
            }

            rc = ble_gap_security_initiate(event->connect.conn_handle);
            if (rc != 0) {
                ESP_LOGW(TAG, "security initiate failed: %d", rc);
            } else {
                ESP_LOGD(TAG, "security initiated");
            }
        }
        return 0;

    case BLE_GAP_EVENT_DISCONNECT:
        ESP_LOGD(TAG, "disconnected: reason=%d",
                 event->disconnect.reason);
        ble_gap_log_conn_desc("disconnected connection",
                              &event->disconnect.conn);
        prefer_bonded_peer = true;
        ble_gap_advertise();
        return 0;

    case BLE_GAP_EVENT_ADV_COMPLETE:
        ESP_LOGD(TAG, "advertising complete: reason=%d",
                 event->adv_complete.reason);
        ble_gap_advertise();
        return 0;

    case BLE_GAP_EVENT_ENC_CHANGE:
        if (event->enc_change.status != 0) {
            ESP_LOGW(TAG, "encryption change failed: %d",
                     event->enc_change.status);
            rc = ble_gap_conn_find(event->enc_change.conn_handle, &desc);
            if (rc == 0) {
                ble_gap_log_conn_desc("encryption failure connection",
                                      &desc);
                rc = ble_store_util_delete_peer(&desc.peer_id_addr);
                ESP_LOGW(TAG, "deleted peer after encryption failure: %d",
                         rc);
            } else {
                ESP_LOGW(TAG, "failed to find connection after encryption failure: %d",
                         rc);
            }
        } else {
            ESP_LOGD(TAG, "encryption changed: handle=%u",
                     event->enc_change.conn_handle);
            rc = ble_gap_conn_find(event->enc_change.conn_handle, &desc);
            if (rc == 0) {
                ble_gap_log_conn_desc("encrypted connection", &desc);
            } else {
                ESP_LOGW(TAG, "failed to find encrypted connection: %d",
                         rc);
            }
        }
        return 0;

    case BLE_GAP_EVENT_REPEAT_PAIRING:
        rc = ble_gap_conn_find(event->repeat_pairing.conn_handle, &desc);
        if (rc != 0) {
            ESP_LOGE(TAG, "failed to find connection for repeat pairing: %d",
                     rc);
            return rc;
        }

        ble_gap_log_conn_desc("repeat pairing connection", &desc);
        ESP_LOGD(TAG,
                 "repeat pairing: cur_key_size=%u cur_authenticated=%u cur_sc=%u new_key_size=%u new_authenticated=%u new_sc=%u new_bonding=%u",
                 event->repeat_pairing.cur_key_size,
                 event->repeat_pairing.cur_authenticated,
                 event->repeat_pairing.cur_sc,
                 event->repeat_pairing.new_key_size,
                 event->repeat_pairing.new_authenticated,
                 event->repeat_pairing.new_sc,
                 event->repeat_pairing.new_bonding);
        rc = ble_store_util_delete_peer(&desc.peer_id_addr);
        ESP_LOGD(TAG, "repeat pairing: deleted old bond: %d", rc);
        return BLE_GAP_REPEAT_PAIRING_RETRY;

    case BLE_GAP_EVENT_PASSKEY_ACTION:
        memset(&sm_io, 0, sizeof(sm_io));
        sm_io.action = event->passkey.params.action;
        ESP_LOGD(TAG, "passkey action: %d",
                 event->passkey.params.action);

        if (event->passkey.params.action == BLE_SM_IOACT_NONE) {
            rc = ble_sm_inject_io(event->passkey.conn_handle, &sm_io);
            ESP_LOGD(TAG, "passkey none injected: %d", rc);
        }
        return 0;

    default:
        return 0;
    }
}

/** @brief 使用当前地址类型和 GATT 主服务 UUID 启动广播。 */
static void ble_gap_advertise(void)
{
    bool try_bonded_peer = prefer_bonded_peer;  ///< 每次只尝试一轮定向广播。
    int rc;                                     ///< 广播启动返回码。

    prefer_bonded_peer = false;
    rc = ble_advertising_start(own_addr_type, ble_gatt_service_uuid(),
                               ble_gap_event, try_bonded_peer);
    if (rc != 0) {
        ESP_LOGE(TAG, "advertising failed: %d", rc);
    }
}

void ble_gap_on_reset(int reason)
{
    ESP_LOGE(TAG, "NimBLE reset: %d", reason);
}

void ble_gap_on_sync(void)
{
    int rc = ble_hs_id_infer_auto(0, &own_addr_type);  ///< 地址类型推断返回码。

    if (rc != 0) {
        ESP_LOGE(TAG, "failed to infer address type: %d", rc);
        return;
    }

    prefer_bonded_peer = true;
    ble_gap_advertise();
}
