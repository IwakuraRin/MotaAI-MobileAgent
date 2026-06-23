/** @file src/ble/gatt.c
 *  @brief Mota BLE GATT 服务定义与访问回调实现。
 */
#include "ble/gatt.h"

#include "ble/stream.h"
#include "esp_log.h"
#include "host/ble_gatt.h"
#include "host/ble_uuid.h"

static const char *TAG = "ble_gatt";  ///< 本模块日志标签。

/** @brief Mota 自定义 UART 风格 GATT 主服务 UUID。 */
static const ble_uuid128_t mota_uart_service_uuid =
    BLE_UUID128_INIT(0x9e, 0xca, 0xdc, 0x24, 0x0e, 0xe5, 0xa9, 0xe0,
                     0x93, 0xf3, 0xa3, 0xb5, 0x01, 0x00, 0x40, 0x6e);

/** @brief 手机写入 JSON 控制消息的 RX characteristic UUID。 */
static const ble_uuid128_t mota_uart_rx_uuid =
    BLE_UUID128_INIT(0x9e, 0xca, 0xdc, 0x24, 0x0e, 0xe5, 0xa9, 0xe0,
                     0x93, 0xf3, 0xa3, 0xb5, 0x02, 0x00, 0x40, 0x6e);

/** @brief 设备通过 notification 发送 JSON 消息的 TX characteristic UUID。 */
static const ble_uuid128_t mota_uart_tx_uuid =
    BLE_UUID128_INIT(0x9e, 0xca, 0xdc, 0x24, 0x0e, 0xe5, 0xa9, 0xe0,
                     0x93, 0xf3, 0xa3, 0xb5, 0x03, 0x00, 0x40, 0x6e);

/** @brief 预留的设备配置 characteristic UUID。 */
static const ble_uuid128_t mota_config_uuid =
    BLE_UUID128_INIT(0x9e, 0xca, 0xdc, 0x24, 0x0e, 0xe5, 0xa9, 0xe0,
                     0x93, 0xf3, 0xa3, 0xb5, 0x04, 0x00, 0x40, 0x6e);

/** @brief 预留的设备信息 characteristic UUID。 */
static const ble_uuid128_t mota_device_info_uuid =
    BLE_UUID128_INIT(0x9e, 0xca, 0xdc, 0x24, 0x0e, 0xe5, 0xa9, 0xe0,
                     0x93, 0xf3, 0xa3, 0xb5, 0x05, 0x00, 0x40, 0x6e);

static int ble_gatt_access(uint16_t conn_handle, uint16_t attr_handle,
                           struct ble_gatt_access_ctxt *ctxt, void *arg);

/** @brief Mota 对外暴露的 GATT 服务表。 */
static const struct ble_gatt_svc_def ble_services[] = {
    {
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = &mota_uart_service_uuid.u,
        .characteristics = (struct ble_gatt_chr_def[]) {
            /* 手机写入的 RX characteristic，支持有响应和无响应写入。 */
            {
                .uuid = &mota_uart_rx_uuid.u,
                .access_cb = ble_gatt_access,
                .flags = BLE_GATT_CHR_F_WRITE |
                         BLE_GATT_CHR_F_WRITE_NO_RSP |
                         BLE_GATT_CHR_F_WRITE_ENC,
            },
            /* 设备发给手机的 TX characteristic，通过 notify 输出。 */
            {
                .uuid = &mota_uart_tx_uuid.u,
                .access_cb = ble_gatt_access,
                .flags = BLE_GATT_CHR_F_NOTIFY |
                         BLE_GATT_CHR_F_NOTIFY_INDICATE_ENC,
                .val_handle = &ble_stream_tx_value_handle,
            },
            /* 预留配置 characteristic，用于后续修改广播名等设置。 */
            {
                .uuid = &mota_config_uuid.u,
                .access_cb = ble_gatt_access,
                .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_READ_ENC |
                         BLE_GATT_CHR_F_WRITE | BLE_GATT_CHR_F_WRITE_ENC,
            },
            /* 预留设备信息 characteristic，用于后续读取设备标识。 */
            {
                .uuid = &mota_device_info_uuid.u,
                .access_cb = ble_gatt_access,
                .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_READ_ENC,
            },
            { 0 },
        },
    },
    { 0 },
};

/** @brief 处理 GATT characteristic 读写访问。 */
static int ble_gatt_access(uint16_t conn_handle, uint16_t attr_handle,
                           struct ble_gatt_access_ctxt *ctxt, void *arg)
{
    (void)conn_handle;
    (void)attr_handle;
    (void)arg;

    switch (ctxt->op) {
    case BLE_GATT_ACCESS_OP_READ_CHR:
        return 0;

    case BLE_GATT_ACCESS_OP_WRITE_CHR:
        if (ble_uuid_cmp(ctxt->chr->uuid, &mota_uart_rx_uuid.u) == 0) {
            return ble_stream_rx_write(ctxt->om);
        }
        return 0;

    default:
        return BLE_ATT_ERR_UNLIKELY;
    }
}

esp_err_t ble_gatt_init(void)
{
    int rc = ble_gatts_count_cfg(ble_services);  ///< GATT 服务资源统计返回码。
    if (rc != 0) {
        ESP_LOGE(TAG, "failed to count GATT services: %d", rc);
        return ESP_FAIL;
    }

    rc = ble_gatts_add_svcs(ble_services);
    if (rc != 0) {
        ESP_LOGE(TAG, "failed to add GATT services: %d", rc);
        return ESP_FAIL;
    }

    return ESP_OK;
}

const ble_uuid128_t *ble_gatt_service_uuid(void)
{
    return &mota_uart_service_uuid;
}
