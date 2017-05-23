// Code generated by counterfeiter. DO NOT EDIT.
package authfakes

import (
	"net/http"
	"sync"

	"github.com/concourse/atc/auth"
)

type FakeRejector struct {
	UnauthorizedStub        func(http.ResponseWriter, *http.Request)
	unauthorizedMutex       sync.RWMutex
	unauthorizedArgsForCall []struct {
		arg1 http.ResponseWriter
		arg2 *http.Request
	}
	ForbiddenStub        func(http.ResponseWriter, *http.Request)
	forbiddenMutex       sync.RWMutex
	forbiddenArgsForCall []struct {
		arg1 http.ResponseWriter
		arg2 *http.Request
	}
	invocations      map[string][][]interface{}
	invocationsMutex sync.RWMutex
}

func (fake *FakeRejector) Unauthorized(arg1 http.ResponseWriter, arg2 *http.Request) {
	fake.unauthorizedMutex.Lock()
	fake.unauthorizedArgsForCall = append(fake.unauthorizedArgsForCall, struct {
		arg1 http.ResponseWriter
		arg2 *http.Request
	}{arg1, arg2})
	fake.recordInvocation("Unauthorized", []interface{}{arg1, arg2})
	fake.unauthorizedMutex.Unlock()
	if fake.UnauthorizedStub != nil {
		fake.UnauthorizedStub(arg1, arg2)
	}
}

func (fake *FakeRejector) UnauthorizedCallCount() int {
	fake.unauthorizedMutex.RLock()
	defer fake.unauthorizedMutex.RUnlock()
	return len(fake.unauthorizedArgsForCall)
}

func (fake *FakeRejector) UnauthorizedArgsForCall(i int) (http.ResponseWriter, *http.Request) {
	fake.unauthorizedMutex.RLock()
	defer fake.unauthorizedMutex.RUnlock()
	return fake.unauthorizedArgsForCall[i].arg1, fake.unauthorizedArgsForCall[i].arg2
}

func (fake *FakeRejector) Forbidden(arg1 http.ResponseWriter, arg2 *http.Request) {
	fake.forbiddenMutex.Lock()
	fake.forbiddenArgsForCall = append(fake.forbiddenArgsForCall, struct {
		arg1 http.ResponseWriter
		arg2 *http.Request
	}{arg1, arg2})
	fake.recordInvocation("Forbidden", []interface{}{arg1, arg2})
	fake.forbiddenMutex.Unlock()
	if fake.ForbiddenStub != nil {
		fake.ForbiddenStub(arg1, arg2)
	}
}

func (fake *FakeRejector) ForbiddenCallCount() int {
	fake.forbiddenMutex.RLock()
	defer fake.forbiddenMutex.RUnlock()
	return len(fake.forbiddenArgsForCall)
}

func (fake *FakeRejector) ForbiddenArgsForCall(i int) (http.ResponseWriter, *http.Request) {
	fake.forbiddenMutex.RLock()
	defer fake.forbiddenMutex.RUnlock()
	return fake.forbiddenArgsForCall[i].arg1, fake.forbiddenArgsForCall[i].arg2
}

func (fake *FakeRejector) Invocations() map[string][][]interface{} {
	fake.invocationsMutex.RLock()
	defer fake.invocationsMutex.RUnlock()
	fake.unauthorizedMutex.RLock()
	defer fake.unauthorizedMutex.RUnlock()
	fake.forbiddenMutex.RLock()
	defer fake.forbiddenMutex.RUnlock()
	copiedInvocations := map[string][][]interface{}{}
	for key, value := range fake.invocations {
		copiedInvocations[key] = value
	}
	return copiedInvocations
}

func (fake *FakeRejector) recordInvocation(key string, args []interface{}) {
	fake.invocationsMutex.Lock()
	defer fake.invocationsMutex.Unlock()
	if fake.invocations == nil {
		fake.invocations = map[string][][]interface{}{}
	}
	if fake.invocations[key] == nil {
		fake.invocations[key] = [][]interface{}{}
	}
	fake.invocations[key] = append(fake.invocations[key], args)
}

var _ auth.Rejector = new(FakeRejector)
