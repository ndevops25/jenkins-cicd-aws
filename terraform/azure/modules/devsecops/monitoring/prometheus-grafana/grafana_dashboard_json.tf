resource "local_file" "grafana_dashboard_json" {
  filename = "modules/devsecops/monitoring/prometheus-grafana/temp_build/dashboard.json"
  content  = jsonencode({
    annotations = {
      list = [
        {
          builtIn    = 1
          datasource = "-- Grafana --"
          enable     = true
          hide       = true
          iconColor  = "rgba(0, 211, 255, 1)"
          name       = "Annotations & Alerts"
          type       = "dashboard"
        }
      ]
    }
    editable      = true
    gnetId        = null
    graphTooltip  = 0
    id            = null
    links         = []
    panels = [
      {
        datasource = "Prometheus"
        fieldConfig = {
          defaults = {
            color = {
              mode = "palette-classic"
            }
            custom = {
              axisLabel         = ""
              axisPlacement     = "auto"
              barAlignment      = 0
              drawStyle         = "line"
              fillOpacity       = 10
              gradientMode      = "none"
              hideFrom = {
                legend  = false
                tooltip = false
                vis     = false
              }
              lineInterpolation = "linear"
              lineWidth         = 1
              pointSize         = 5
              scaleDistribution = {
                type = "linear"
              }
              showPoints  = "never"
              spanNulls   = false
              stacking = {
                group = "A"
                mode  = "none"
              }
              thresholdsStyle = {
                mode = "off"
              }
            }
            mappings = []
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  color = "green"
                  value = null
                },
                {
                  color = "red"
                  value = 80
                }
              ]
            }
            unit = "percent"
          }
          overrides = []
        }
        gridPos = {
          h = 8
          w = 12
          x = 0
          y = 0
        }
        id = 1
        options = {
          legend = {
            calcs       = []
            displayMode = "list"
            placement   = "bottom"
          }
          tooltip = {
            mode = "single"
          }
        }
        pluginVersion = "8.0.0"
        targets = [
          {
            expr           = "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
            format         = "time_series"
            interval       = ""
            intervalFactor = 1
            legendFormat   = "CPU Usage"
            refId          = "A"
          }
        ]
        title = "System Overview"
        type  = "timeseries"
      }
    ]
    schemaVersion = 27
    style         = "dark"
    tags          = ["monitoring", "prometheus", "system"]
    templating = {
      list = []
    }
    time = {
      from = "now-1h"
      to   = "now"
    }
    timepicker = {}
    timezone   = ""
    title      = "Infrastructure Monitoring"
    uid        = "monitoring-dashboard"
    version    = 1
  })
}