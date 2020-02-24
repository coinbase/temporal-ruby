package main

import (
	"fmt"
	"os"

	"go.uber.org/yarpc"
	"go.uber.org/yarpc/transport/http"
	"go.uber.org/yarpc/transport/tchannel"
	"go.uber.org/zap"

	"github.com/coinbase/cadence-ruby/proxy/internal"
	"github.com/coinbase/cadence-ruby/proxy/gen/cadence/workflowserviceserver"
)

func main() {
	bindAddress := "127.0.0.1:6666"
	cadenceAddress := "127.0.0.1:7933"

	if in := os.Getenv("BIND_ADDRESS"); in != "" {
		bindAddress = in
	}

	if out := os.Getenv("CADENCE_ADDRESS"); out != "" {
		cadenceAddress = out
	}

	logger, _ := zap.NewProduction()
	defer logger.Sync()

	dispatcher := initDispatcher(logger, bindAddress, cadenceAddress)
	handler := internal.NewProxyHandler(dispatcher.ClientConfig("cadence-frontend"))
	dispatcher.Register(workflowserviceserver.New(handler))

	if err := dispatcher.Start(); err != nil {
		fmt.Println("failed to start Dispatcher: %v", err)
		return
	}
	defer dispatcher.Stop()

	select {}
}

func initDispatcher(logger *zap.Logger, bindAddress string, cadenceAddress string) *yarpc.Dispatcher {
	httpTransport := http.NewTransport()
	tchannelTransport, err := tchannel.NewChannelTransport(tchannel.ServiceName("cadence-proxy-client"))
	if err != nil {
		fmt.Println("failed to generate transport: %v", err)
	}

	config := yarpc.Config{
		Name: "cadence-proxy",
		Inbounds: yarpc.Inbounds{
			httpTransport.NewInbound(bindAddress),
		},
		Outbounds: yarpc.Outbounds{
			"cadence-frontend": {
				Unary: tchannelTransport.NewSingleOutbound(cadenceAddress),
			},
		},
		Logging: yarpc.LoggingConfig{
			Zap: logger,
		},
	}

	if timing := os.Getenv("TIMING"); timing == "1" {
		config.OutboundMiddleware = yarpc.OutboundMiddleware{
			Unary: yarpc.UnaryOutboundMiddleware(internal.TimingLogMiddleware{}),
		}
	}

	return yarpc.NewDispatcher(config)
}
