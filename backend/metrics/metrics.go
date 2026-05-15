package metrics

import (
	"fmt"
	"net/http"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

type requestKey struct {
	Method string
	Route  string
	Status int
}

var (
	mu              sync.RWMutex
	requestTotals   = map[requestKey]uint64{}
	requestDuration = map[requestKey]float64{}
)

func Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		c.Next()

		route := c.FullPath()
		if route == "" {
			route = c.Request.URL.Path
		}

		key := requestKey{
			Method: c.Request.Method,
			Route:  route,
			Status: c.Writer.Status(),
		}

		mu.Lock()
		requestTotals[key]++
		requestDuration[key] += time.Since(start).Seconds()
		mu.Unlock()
	}
}

func Handler(c *gin.Context) {
	mu.RLock()
	defer mu.RUnlock()

	keys := make([]requestKey, 0, len(requestTotals))
	for key := range requestTotals {
		keys = append(keys, key)
	}

	sort.Slice(keys, func(i, j int) bool {
		if keys[i].Route != keys[j].Route {
			return keys[i].Route < keys[j].Route
		}
		if keys[i].Method != keys[j].Method {
			return keys[i].Method < keys[j].Method
		}
		return keys[i].Status < keys[j].Status
	})

	var b strings.Builder
	b.WriteString("# HELP skillpulse_build_info Static build information for the SkillPulse API.\n")
	b.WriteString("# TYPE skillpulse_build_info gauge\n")
	b.WriteString("skillpulse_build_info{service=\"backend\"} 1\n\n")

	b.WriteString("# HELP skillpulse_http_requests_total Total HTTP requests served by the SkillPulse API.\n")
	b.WriteString("# TYPE skillpulse_http_requests_total counter\n")
	for _, key := range keys {
		fmt.Fprintf(
			&b,
			"skillpulse_http_requests_total{method=%q,route=%q,status=%q} %d\n",
			escapeLabel(key.Method),
			escapeLabel(key.Route),
			escapeLabel(fmt.Sprintf("%d", key.Status)),
			requestTotals[key],
		)
	}
	b.WriteString("\n")

	b.WriteString("# HELP skillpulse_http_request_duration_seconds_sum Total request duration in seconds.\n")
	b.WriteString("# TYPE skillpulse_http_request_duration_seconds_sum counter\n")
	for _, key := range keys {
		fmt.Fprintf(
			&b,
			"skillpulse_http_request_duration_seconds_sum{method=%q,route=%q,status=%q} %.6f\n",
			escapeLabel(key.Method),
			escapeLabel(key.Route),
			escapeLabel(fmt.Sprintf("%d", key.Status)),
			requestDuration[key],
		)
	}
	b.WriteString("\n")

	b.WriteString("# HELP skillpulse_http_request_duration_seconds_count Total requests with duration observations.\n")
	b.WriteString("# TYPE skillpulse_http_request_duration_seconds_count counter\n")
	for _, key := range keys {
		fmt.Fprintf(
			&b,
			"skillpulse_http_request_duration_seconds_count{method=%q,route=%q,status=%q} %d\n",
			escapeLabel(key.Method),
			escapeLabel(key.Route),
			escapeLabel(fmt.Sprintf("%d", key.Status)),
			requestTotals[key],
		)
	}

	c.Data(http.StatusOK, "text/plain; version=0.0.4; charset=utf-8", []byte(b.String()))
}

func escapeLabel(value string) string {
	replacer := strings.NewReplacer("\\", "\\\\", "\n", "\\n", "\"", "\\\"")
	return replacer.Replace(value)
}

