package internal

import (
	"context"

	"go.uber.org/yarpc/api/transport"

	"github.com/coinbase/cadence-ruby/proxy/gen/shared"
	"github.com/coinbase/cadence-ruby/proxy/gen/cadence/workflowserviceclient"
	"github.com/coinbase/cadence-ruby/proxy/gen/cadence/workflowserviceserver"
)

func NewProxyHandler(clientConfig transport.ClientConfig) *proxyHandler {
	client := workflowserviceclient.New(clientConfig)

	return &proxyHandler{client: client}
}

type proxyHandler struct {
	workflowserviceserver.Interface

	client workflowserviceclient.Interface
}

func (h *proxyHandler) CountWorkflowExecutions(ctx context.Context, CountRequest *shared.CountWorkflowExecutionsRequest) (*shared.CountWorkflowExecutionsResponse, error) {
	return h.client.CountWorkflowExecutions(ctx, CountRequest)
}

func (h *proxyHandler) DeprecateDomain(ctx context.Context, DeprecateRequest *shared.DeprecateDomainRequest) error {
	return h.client.DeprecateDomain(ctx, DeprecateRequest)
}

func (h *proxyHandler) DescribeDomain(ctx context.Context, DescribeRequest *shared.DescribeDomainRequest) (*shared.DescribeDomainResponse, error) {
	return h.client.DescribeDomain(ctx, DescribeRequest)
}

func (h *proxyHandler) DescribeTaskList(ctx context.Context, Request *shared.DescribeTaskListRequest) (*shared.DescribeTaskListResponse, error) {
	return h.client.DescribeTaskList(ctx, Request)
}

func (h *proxyHandler) DescribeWorkflowExecution(ctx context.Context, DescribeRequest *shared.DescribeWorkflowExecutionRequest) (*shared.DescribeWorkflowExecutionResponse, error) {
	return h.client.DescribeWorkflowExecution(ctx, DescribeRequest)
}

func (h *proxyHandler) GetSearchAttributes(ctx context.Context) (*shared.GetSearchAttributesResponse, error) {
	return h.client.GetSearchAttributes(ctx)
}

func (h *proxyHandler) GetWorkflowExecutionHistory(ctx context.Context, GetRequest *shared.GetWorkflowExecutionHistoryRequest) (*shared.GetWorkflowExecutionHistoryResponse, error) {
	return h.client.GetWorkflowExecutionHistory(ctx, GetRequest)
}

func (h *proxyHandler) ListArchivedWorkflowExecutions(ctx context.Context, ListRequest *shared.ListArchivedWorkflowExecutionsRequest) (*shared.ListArchivedWorkflowExecutionsResponse, error) {
	return h.client.ListArchivedWorkflowExecutions(ctx, ListRequest)
}

func (h *proxyHandler) ListClosedWorkflowExecutions(ctx context.Context, ListRequest *shared.ListClosedWorkflowExecutionsRequest) (*shared.ListClosedWorkflowExecutionsResponse, error) {
	return h.client.ListClosedWorkflowExecutions(ctx, ListRequest)
}

func (h *proxyHandler) ListDomains(ctx context.Context, ListRequest *shared.ListDomainsRequest) (*shared.ListDomainsResponse, error) {
	return h.client.ListDomains(ctx, ListRequest)
}

func (h *proxyHandler) ListOpenWorkflowExecutions(ctx context.Context, ListRequest *shared.ListOpenWorkflowExecutionsRequest) (*shared.ListOpenWorkflowExecutionsResponse, error) {
	return h.client.ListOpenWorkflowExecutions(ctx, ListRequest)
}

func (h *proxyHandler) ListWorkflowExecutions(ctx context.Context, ListRequest *shared.ListWorkflowExecutionsRequest) (*shared.ListWorkflowExecutionsResponse, error) {
	return h.client.ListWorkflowExecutions(ctx, ListRequest)
}

func (h *proxyHandler) PollForActivityTask(ctx context.Context, PollRequest *shared.PollForActivityTaskRequest) (*shared.PollForActivityTaskResponse, error) {
	return h.client.PollForActivityTask(ctx, PollRequest)
}

func (h *proxyHandler) PollForDecisionTask(ctx context.Context, PollRequest *shared.PollForDecisionTaskRequest) (*shared.PollForDecisionTaskResponse, error) {
	return h.client.PollForDecisionTask(ctx, PollRequest)
}

func (h *proxyHandler) QueryWorkflow(ctx context.Context, QueryRequest *shared.QueryWorkflowRequest) (*shared.QueryWorkflowResponse, error) {
	return h.client.QueryWorkflow(ctx, QueryRequest)
}

func (h *proxyHandler) RecordActivityTaskHeartbeat(ctx context.Context, HeartbeatRequest *shared.RecordActivityTaskHeartbeatRequest) (*shared.RecordActivityTaskHeartbeatResponse, error) {
	return h.client.RecordActivityTaskHeartbeat(ctx, HeartbeatRequest)
}

func (h *proxyHandler) RecordActivityTaskHeartbeatByID(ctx context.Context, HeartbeatRequest *shared.RecordActivityTaskHeartbeatByIDRequest) (*shared.RecordActivityTaskHeartbeatResponse, error) {
	return h.client.RecordActivityTaskHeartbeatByID(ctx, HeartbeatRequest)
}

func (h *proxyHandler) RegisterDomain(ctx context.Context, RegisterRequest *shared.RegisterDomainRequest) error {
	return h.client.RegisterDomain(ctx, RegisterRequest)
}

func (h *proxyHandler) RequestCancelWorkflowExecution(ctx context.Context, CancelRequest *shared.RequestCancelWorkflowExecutionRequest) error {
	return h.client.RequestCancelWorkflowExecution(ctx, CancelRequest)
}

func (h *proxyHandler) ResetStickyTaskList(ctx context.Context, ResetRequest *shared.ResetStickyTaskListRequest) (*shared.ResetStickyTaskListResponse, error) {
	return h.client.ResetStickyTaskList(ctx, ResetRequest)
}

func (h *proxyHandler) ResetWorkflowExecution(ctx context.Context, ResetRequest *shared.ResetWorkflowExecutionRequest) (*shared.ResetWorkflowExecutionResponse, error) {
	return h.client.ResetWorkflowExecution(ctx, ResetRequest)
}

func (h *proxyHandler) RespondActivityTaskCanceled(ctx context.Context, CanceledRequest *shared.RespondActivityTaskCanceledRequest) error {
	return h.client.RespondActivityTaskCanceled(ctx, CanceledRequest)
}

func (h *proxyHandler) RespondActivityTaskCanceledByID(ctx context.Context, CanceledRequest *shared.RespondActivityTaskCanceledByIDRequest) error {
	return h.client.RespondActivityTaskCanceledByID(ctx, CanceledRequest)
}

func (h *proxyHandler) RespondActivityTaskCompleted(ctx context.Context, CompleteRequest *shared.RespondActivityTaskCompletedRequest) error {
	return h.client.RespondActivityTaskCompleted(ctx, CompleteRequest)
}

func (h *proxyHandler) RespondActivityTaskCompletedByID(ctx context.Context, CompleteRequest *shared.RespondActivityTaskCompletedByIDRequest) error {
	return h.client.RespondActivityTaskCompletedByID(ctx, CompleteRequest)
}

func (h *proxyHandler) RespondActivityTaskFailed(ctx context.Context, FailRequest *shared.RespondActivityTaskFailedRequest) error {
	return h.client.RespondActivityTaskFailed(ctx, FailRequest)
}

func (h *proxyHandler) RespondActivityTaskFailedByID(ctx context.Context, FailRequest *shared.RespondActivityTaskFailedByIDRequest) error {
	return h.client.RespondActivityTaskFailedByID(ctx, FailRequest)
}

func (h *proxyHandler) RespondDecisionTaskCompleted(ctx context.Context, CompleteRequest *shared.RespondDecisionTaskCompletedRequest) (*shared.RespondDecisionTaskCompletedResponse, error) {
	return h.client.RespondDecisionTaskCompleted(ctx, CompleteRequest)
}

func (h *proxyHandler) RespondDecisionTaskFailed(ctx context.Context, FailedRequest *shared.RespondDecisionTaskFailedRequest) error {
	return h.client.RespondDecisionTaskFailed(ctx, FailedRequest)
}

func (h *proxyHandler) RespondQueryTaskCompleted(ctx context.Context, CompleteRequest *shared.RespondQueryTaskCompletedRequest) error {
	return h.client.RespondQueryTaskCompleted(ctx, CompleteRequest)
}

func (h *proxyHandler) ScanWorkflowExecutions(ctx context.Context, ListRequest *shared.ListWorkflowExecutionsRequest) (*shared.ListWorkflowExecutionsResponse, error) {
	return h.client.ScanWorkflowExecutions(ctx, ListRequest)
}

func (h *proxyHandler) SignalWithStartWorkflowExecution(ctx context.Context, SignalWithStartRequest *shared.SignalWithStartWorkflowExecutionRequest) (*shared.StartWorkflowExecutionResponse, error) {
	return h.client.SignalWithStartWorkflowExecution(ctx, SignalWithStartRequest)
}

func (h *proxyHandler) SignalWorkflowExecution(ctx context.Context, SignalRequest *shared.SignalWorkflowExecutionRequest) error {
	return h.client.SignalWorkflowExecution(ctx, SignalRequest)
}

func (h *proxyHandler) StartWorkflowExecution(ctx context.Context, StartRequest *shared.StartWorkflowExecutionRequest) (*shared.StartWorkflowExecutionResponse, error) {
	return h.client.StartWorkflowExecution(ctx, StartRequest)
}

func (h *proxyHandler) TerminateWorkflowExecution(ctx context.Context, TerminateRequest *shared.TerminateWorkflowExecutionRequest) error {
	return h.client.TerminateWorkflowExecution(ctx, TerminateRequest)
}

func (h *proxyHandler) UpdateDomain(ctx context.Context, UpdateRequest *shared.UpdateDomainRequest) (*shared.UpdateDomainResponse, error) {
	return h.client.UpdateDomain(ctx, UpdateRequest)
}
