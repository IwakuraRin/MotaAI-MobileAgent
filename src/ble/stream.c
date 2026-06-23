/** @file src/ble/stream.c
 *  @brief BLE JSON 行协议收发流实现。
 */
#include "ble/stream.h"

#include <string.h>

#include "esp_err.h"
#include "esp_log.h"
#include "host/ble_hs.h"

#define BLE_STREAM_RX_BUFFER_SIZE 1024  ///< RX JSON 行缓冲区容量，单位字节。

static const char *TAG = "ble_stream";  ///< 本模块日志标签。

uint16_t ble_stream_tx_value_handle;  ///< TX characteristic value handle，由 GATT 注册时写入。
static uint16_t conn_handle = BLE_HS_CONN_HANDLE_NONE;  ///< 当前连接 handle，未连接时为 BLE_HS_CONN_HANDLE_NONE。
static uint16_t mtu = BLE_ATT_MTU_DFLT;                 ///< 当前连接协商出的 ATT MTU。
static bool tx_subscribed;                              ///< 手机是否已订阅 TX notification。
static char rx_buffer[BLE_STREAM_RX_BUFFER_SIZE];       ///< 尚未遇到换行符的 RX JSON 文本缓冲区。
static size_t rx_buffer_len;                            ///< rx_buffer 当前已写入字节数。
static ble_stream_rx_callback_t rx_callback;            ///< 完整 JSON 行接收回调。

/** @brief 清除连接相关的 TX/RX 运行状态。 */
static void ble_stream_reset_link(void)
{
    conn_handle = BLE_HS_CONN_HANDLE_NONE;
    mtu = BLE_ATT_MTU_DFLT;
    tx_subscribed = false;
    rx_buffer_len = 0;
}

void ble_stream_on_gap_event(const struct ble_gap_event *event)
{
    switch (event->type) {
    case BLE_GAP_EVENT_CONNECT:
        if (event->connect.status == 0) {
            conn_handle = event->connect.conn_handle;
            mtu = BLE_ATT_MTU_DFLT;
            tx_subscribed = false;
            ESP_LOGD(TAG, "link opened: handle=%u", conn_handle);
        } else {
            ESP_LOGW(TAG, "connect failed, reset stream state: %d",
                     event->connect.status);
            ble_stream_reset_link();
        }
        break;

    case BLE_GAP_EVENT_DISCONNECT:
        ESP_LOGD(TAG, "link closed: handle=%u subscribed=%u rx_len=%u",
                 conn_handle, tx_subscribed, (unsigned)rx_buffer_len);
        ble_stream_reset_link();
        break;

    case BLE_GAP_EVENT_SUBSCRIBE:
        if (event->subscribe.attr_handle == ble_stream_tx_value_handle) {
            tx_subscribed = event->subscribe.cur_notify;
            ESP_LOGD(TAG,
                     "tx subscribe: conn=%u attr=%u reason=%u prev_notify=%u cur_notify=%u prev_indicate=%u cur_indicate=%u",
                     event->subscribe.conn_handle,
                     event->subscribe.attr_handle,
                     event->subscribe.reason,
                     event->subscribe.prev_notify,
                     event->subscribe.cur_notify,
                     event->subscribe.prev_indicate,
                     event->subscribe.cur_indicate);
        }
        break;

    case BLE_GAP_EVENT_MTU:
        mtu = event->mtu.value;
        ESP_LOGD(TAG, "mtu updated: conn=%u channel=%u mtu=%u",
                 event->mtu.conn_handle, event->mtu.channel_id,
                 event->mtu.value);
        break;

    default:
        break;
    }
}

/** @brief 将 RX 缓冲区中的一行 JSON 交给上层回调。 */
static int ble_stream_emit_rx_json(void)
{
    if (rx_callback != NULL && rx_buffer_len > 0) {
        ESP_LOGD(TAG, "rx json line: len=%u", (unsigned)rx_buffer_len);
        rx_callback(rx_buffer, rx_buffer_len);
    }

    rx_buffer_len = 0;
    return 0;
}

int ble_stream_rx_write(struct os_mbuf *om)
{
    uint16_t len = OS_MBUF_PKTLEN(om);             ///< 本次写入 mbuf 的总字节数。
    uint8_t chunk[BLE_STREAM_RX_BUFFER_SIZE];      ///< 扁平化后的本次写入数据。
    int rc;                                        ///< NimBLE mbuf 转换返回码。

    ESP_LOGD(TAG, "rx write: len=%u buffered=%u", len,
             (unsigned)rx_buffer_len);
    if (len > sizeof(chunk)) {
        ESP_LOGW(TAG, "rx write too large: len=%u max=%u", len,
                 (unsigned)sizeof(chunk));
        return BLE_ATT_ERR_INVALID_ATTR_VALUE_LEN;
    }

    rc = ble_hs_mbuf_to_flat(om, chunk, sizeof(chunk), &len);
    if (rc != 0) {
        ESP_LOGW(TAG, "rx flatten failed: %d", rc);
        return BLE_ATT_ERR_UNLIKELY;
    }

    for (uint16_t i = 0; i < len; ++i) {  ///< 逐字节扫描本次写入数据。
        uint8_t ch = chunk[i];            ///< 当前正在处理的 RX 字节。

        if (ch == '\r') {
            continue;
        }

        if (ch == '\n') {
            rc = ble_stream_emit_rx_json();
            if (rc != 0) {
                return BLE_ATT_ERR_UNLIKELY;
            }
            continue;
        }

        if (rx_buffer_len >= sizeof(rx_buffer)) {
            ESP_LOGW(TAG, "rx buffer overflow: capacity=%u",
                     (unsigned)sizeof(rx_buffer));
            rx_buffer_len = 0;
            return BLE_ATT_ERR_INVALID_ATTR_VALUE_LEN;
        }

        rx_buffer[rx_buffer_len++] = (char)ch;
    }

    return 0;
}

bool ble_stream_tx_ready(void)
{
    return conn_handle != BLE_HS_CONN_HANDLE_NONE && tx_subscribed;
}

/** @brief 发送一个不超过当前 MTU 负载限制的 notification 分片。 */
static esp_err_t ble_stream_notify_chunk(const uint8_t *data, size_t len)
{
    struct os_mbuf *om = ble_hs_mbuf_from_flat(data, len);  ///< notification 使用的 NimBLE mbuf。
    int rc;                                                 ///< notification 发送返回码。

    if (om == NULL) {
        ESP_LOGW(TAG, "notify allocation failed: len=%u", (unsigned)len);
        return ESP_ERR_NO_MEM;
    }

    rc = ble_gatts_notify_custom(conn_handle, ble_stream_tx_value_handle, om);
    if (rc != 0) {
        ESP_LOGW(TAG, "notify failed: rc=%d handle=%u attr=%u len=%u",
                 rc, conn_handle, ble_stream_tx_value_handle,
                 (unsigned)len);
        return ESP_FAIL;
    }

    return ESP_OK;
}

esp_err_t ble_stream_tx_json(const char *json, size_t len)
{
    size_t offset = 0;       ///< 当前已经发送的 JSON 文本偏移。
    size_t payload_size;     ///< 单个 notification 可承载的最大 payload 字节数。
    esp_err_t err;           ///< 分片发送返回码。

    if (json == NULL && len > 0) {
        return ESP_ERR_INVALID_ARG;
    }

    if (!ble_stream_tx_ready()) {
        ESP_LOGD(TAG, "tx not ready: conn=%u subscribed=%u",
                 conn_handle, tx_subscribed);
        return ESP_ERR_INVALID_STATE;
    }

    ESP_LOGD(TAG, "tx json: len=%u mtu=%u", (unsigned)len, mtu);
    payload_size = mtu > 3 ? (size_t)mtu - 3 : 20;
    while (offset < len) {
        size_t chunk_len = len - offset;  ///< 本次 notification 分片长度。
        if (chunk_len > payload_size) {
            chunk_len = payload_size;
        }

        err = ble_stream_notify_chunk((const uint8_t *)json + offset,
                                      chunk_len);
        if (err != ESP_OK) {
            return err;
        }

        offset += chunk_len;
    }

    return ble_stream_notify_chunk((const uint8_t *)"\n", 1);
}

void ble_stream_set_rx_callback(ble_stream_rx_callback_t callback)
{
    rx_callback = callback;
}
