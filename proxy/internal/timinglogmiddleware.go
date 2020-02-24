package internal


import (
	"context"
	"time"
	"fmt"

	"go.uber.org/yarpc/api/transport"
)

type TimingLogMiddleware struct{}

func (TimingLogMiddleware) Call(ctx context.Context, request *transport.Request, out transport.UnaryOutbound) (*transport.Response, error) {
	start := time.Now()

	result, err := out.Call(ctx, request)

	elapsed := time.Since(start).Milliseconds()
  fmt.Printf("Request %q took %dms\n", request.Procedure, elapsed)

	return result, err
}
