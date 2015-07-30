// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is autogenerated by:
//     mojo/public/tools/bindings/mojom_bindings_generator.py
// For:
//     mojom/echo.mojom
//

package echo

import (
	"fmt"
	"mojo/public/go/bindings"
	"mojo/public/go/system"
	"sort"
)

type Echo interface {
	EchoString(inValue *string) (outValue *string, err error)
}

var echo_Name = "mojo::examples::Echo"

type Echo_Request bindings.InterfaceRequest

func (r *Echo_Request) Name() string {
	return echo_Name
}

type Echo_Pointer bindings.InterfacePointer

func (p *Echo_Pointer) Name() string {
	return echo_Name
}

type Echo_ServiceFactory struct {
	Delegate Echo_Factory
}

type Echo_Factory interface {
	Create(request Echo_Request)
}

func (f *Echo_ServiceFactory) Name() string {
	return echo_Name
}

func (f *Echo_ServiceFactory) Create(messagePipe system.MessagePipeHandle) {
	request := Echo_Request{bindings.NewMessagePipeHandleOwner(messagePipe)}
	f.Delegate.Create(request)
}

// CreateMessagePipeForEcho creates a message pipe for use with the
// Echo interface with a Echo_Request on one end and a Echo_Pointer on the other.
func CreateMessagePipeForEcho() (Echo_Request, Echo_Pointer) {
	r, p := bindings.CreateMessagePipeForMojoInterface()
	return Echo_Request(r), Echo_Pointer(p)
}

const echo_EchoString_Name uint32 = 0

type Echo_Proxy struct {
	router *bindings.Router
	ids    bindings.Counter
}

func NewEchoProxy(p Echo_Pointer, waiter bindings.AsyncWaiter) *Echo_Proxy {
	return &Echo_Proxy{
		bindings.NewRouter(p.PassMessagePipe(), waiter),
		bindings.NewCounter(),
	}
}

func (p *Echo_Proxy) Close_Proxy() {
	p.router.Close()
}

type echo_EchoString_Params struct {
	inValue *string
}

func (s *echo_EchoString_Params) Encode(encoder *bindings.Encoder) error {
	encoder.StartStruct(8, 0)
	if s.inValue == nil {
		encoder.WriteNullPointer()
	} else {
		if err := encoder.WritePointer(); err != nil {
			return err
		}
		if err := encoder.WriteString((*s.inValue)); err != nil {
			return err
		}
	}
	if err := encoder.Finish(); err != nil {
		return err
	}
	return nil
}

var echo_EchoString_Params_Versions []bindings.DataHeader = []bindings.DataHeader{
	bindings.DataHeader{16, 0},
}

func (s *echo_EchoString_Params) Decode(decoder *bindings.Decoder) error {
	header, err := decoder.StartStruct()
	if err != nil {
		return err
	}
	index := sort.Search(len(echo_EchoString_Params_Versions), func(i int) bool {
		return echo_EchoString_Params_Versions[i].ElementsOrVersion >= header.ElementsOrVersion
	})
	if index < len(echo_EchoString_Params_Versions) {
		if echo_EchoString_Params_Versions[index].ElementsOrVersion > header.ElementsOrVersion {
			index--
		}
		expectedSize := echo_EchoString_Params_Versions[index].Size
		if expectedSize != header.Size {
			return &bindings.ValidationError{bindings.UnexpectedStructHeader,
				fmt.Sprintf("invalid struct header size: should be %d, but was %d", expectedSize, header.Size),
			}
		}
	}
	if header.ElementsOrVersion >= 0 {
		pointer0, err := decoder.ReadPointer()
		if err != nil {
			return err
		}
		if pointer0 == 0 {
			s.inValue = nil
		} else {
			s.inValue = new(string)
			value0, err := decoder.ReadString()
			if err != nil {
				return err
			}
			(*s.inValue) = value0
		}
	}
	if err := decoder.Finish(); err != nil {
		return err
	}
	return nil
}

type echo_EchoString_ResponseParams struct {
	outValue *string
}

func (s *echo_EchoString_ResponseParams) Encode(encoder *bindings.Encoder) error {
	encoder.StartStruct(8, 0)
	if s.outValue == nil {
		encoder.WriteNullPointer()
	} else {
		if err := encoder.WritePointer(); err != nil {
			return err
		}
		if err := encoder.WriteString((*s.outValue)); err != nil {
			return err
		}
	}
	if err := encoder.Finish(); err != nil {
		return err
	}
	return nil
}

var echo_EchoString_ResponseParams_Versions []bindings.DataHeader = []bindings.DataHeader{
	bindings.DataHeader{16, 0},
}

func (s *echo_EchoString_ResponseParams) Decode(decoder *bindings.Decoder) error {
	header, err := decoder.StartStruct()
	if err != nil {
		return err
	}
	index := sort.Search(len(echo_EchoString_ResponseParams_Versions), func(i int) bool {
		return echo_EchoString_ResponseParams_Versions[i].ElementsOrVersion >= header.ElementsOrVersion
	})
	if index < len(echo_EchoString_ResponseParams_Versions) {
		if echo_EchoString_ResponseParams_Versions[index].ElementsOrVersion > header.ElementsOrVersion {
			index--
		}
		expectedSize := echo_EchoString_ResponseParams_Versions[index].Size
		if expectedSize != header.Size {
			return &bindings.ValidationError{bindings.UnexpectedStructHeader,
				fmt.Sprintf("invalid struct header size: should be %d, but was %d", expectedSize, header.Size),
			}
		}
	}
	if header.ElementsOrVersion >= 0 {
		pointer0, err := decoder.ReadPointer()
		if err != nil {
			return err
		}
		if pointer0 == 0 {
			s.outValue = nil
		} else {
			s.outValue = new(string)
			value0, err := decoder.ReadString()
			if err != nil {
				return err
			}
			(*s.outValue) = value0
		}
	}
	if err := decoder.Finish(); err != nil {
		return err
	}
	return nil
}

func (p *Echo_Proxy) EchoString(inValue *string) (outValue *string, err error) {
	payload := &echo_EchoString_Params{
		inValue,
	}
	header := bindings.MessageHeader{
		Type:      echo_EchoString_Name,
		Flags:     bindings.MessageExpectsResponseFlag,
		RequestId: p.ids.Count(),
	}
	var message *bindings.Message
	if message, err = bindings.EncodeMessage(header, payload); err != nil {
		err = fmt.Errorf("can't encode request: %v", err.Error())
		p.Close_Proxy()
		return
	}
	readResult := <-p.router.AcceptWithResponse(message)
	if err = readResult.Error; err != nil {
		p.Close_Proxy()
		return
	}
	if readResult.Message.Header.Flags != bindings.MessageIsResponseFlag {
		err = &bindings.ValidationError{bindings.MessageHeaderInvalidFlags,
			fmt.Sprintf("invalid message header flag: %v", readResult.Message.Header.Flags),
		}
		return
	}
	if got, want := readResult.Message.Header.Type, echo_EchoString_Name; got != want {
		err = &bindings.ValidationError{bindings.MessageHeaderUnknownMethod,
			fmt.Sprintf("invalid method in response: expected %v, got %v", want, got),
		}
		return
	}
	var response echo_EchoString_ResponseParams
	if err = readResult.Message.DecodePayload(&response); err != nil {
		p.Close_Proxy()
		return
	}
	outValue = response.outValue
	return
}

type echo_Stub struct {
	connector *bindings.Connector
	impl      Echo
}

func NewEchoStub(r Echo_Request, impl Echo, waiter bindings.AsyncWaiter) *bindings.Stub {
	connector := bindings.NewConnector(r.PassMessagePipe(), waiter)
	return bindings.NewStub(connector, &echo_Stub{connector, impl})
}

func (s *echo_Stub) Accept(message *bindings.Message) (err error) {
	switch message.Header.Type {
	case echo_EchoString_Name:
		if message.Header.Flags != bindings.MessageExpectsResponseFlag {
			return &bindings.ValidationError{bindings.MessageHeaderInvalidFlags,
				fmt.Sprintf("invalid message header flag: %v", message.Header.Flags),
			}
		}
		var request echo_EchoString_Params
		if err := message.DecodePayload(&request); err != nil {
			return err
		}
		var response echo_EchoString_ResponseParams
		response.outValue, err = s.impl.EchoString(request.inValue)
		if err != nil {
			return
		}
		header := bindings.MessageHeader{
			Type:      echo_EchoString_Name,
			Flags:     bindings.MessageIsResponseFlag,
			RequestId: message.Header.RequestId,
		}
		message, err = bindings.EncodeMessage(header, &response)
		if err != nil {
			return err
		}
		return s.connector.WriteMessage(message)
	default:
		return &bindings.ValidationError{
			bindings.MessageHeaderUnknownMethod,
			fmt.Sprintf("unknown method %v", message.Header.Type),
		}
	}
	return
}
