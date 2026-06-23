/** @file src/ble/ble.c
 *  @brief Mota BLE 对外门面和 NimBLE 初始化实现。
 */
#include "ble/ble.h"

#include "ble/gap.h"
#include "ble/gatt.h"
#include "ble/stream.h"
#include "esp_err.h"
#include "esp_log.h"
#include "host/ble_hs.h"
#include "host/ble_sm.h"
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "services/gap/ble_svc_gap.h"
#include "services/gatt/ble_svc_gatt.h"

static const char *TAG = "ble";  ///< 本模块日志标签。

void ble_store_config_init(void);

/** @brief NimBLE host FreeRTOS 任务入口。 */
static void ble_host_task(void *param)
{
    (void)param;

    nimble_port_run();
    nimble_port_freertos_deinit();
}

esp_err_t ble_init(void)
{
    int rc;  ///< NimBLE 或子模块初始化返回码。

    rc = nimble_port_init();
    if (rc != 0) {
        ESP_LOGE(TAG, "failed to initialize NimBLE: %d", rc);
        return ESP_FAIL;
    }

    ble_svc_gap_init();
    ble_svc_gatt_init();
    rc = ble_gatt_init();
    if (rc != ESP_OK) {
        ESP_LOGE(TAG, "failed to initialize GATT");
        return rc;
    }

    ble_hs_cfg.reset_cb = ble_gap_on_reset;
    ble_hs_cfg.sync_cb = ble_gap_on_sync;
    ble_hs_cfg.store_status_cb = ble_store_util_status_rr;
    ble_hs_cfg.sm_io_cap = BLE_HS_IO_NO_INPUT_OUTPUT;
    ble_hs_cfg.sm_bonding = 1;
    ble_hs_cfg.sm_mitm = 0;
    ble_hs_cfg.sm_sc = 0;
    ble_hs_cfg.sm_our_key_dist = BLE_SM_PAIR_KEY_DIST_ENC;
    ble_hs_cfg.sm_their_key_dist = BLE_SM_PAIR_KEY_DIST_ENC;
    ble_store_config_init();

    nimble_port_freertos_init(ble_host_task);
    return ESP_OK;
}

esp_err_t ble_tx_json(const char *json, size_t len)
{
    return ble_stream_tx_json(json, len);
}

bool ble_tx_ready(void)
{
    return ble_stream_tx_ready();
}

void ble_set_rx_json_callback(ble_rx_json_callback_t callback)
{
    ble_stream_set_rx_callback(callback);
}
