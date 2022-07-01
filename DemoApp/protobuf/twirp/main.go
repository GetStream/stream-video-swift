package main

import (
	"io"
	"io/ioutil"
	"os"
	"strings"

	"github.com/CrazyHulk/protoc-gen-swiftwirp/generator"

	"github.com/gogo/protobuf/proto"

	gogogen "github.com/gogo/protobuf/protoc-gen-gogo/generator"
	plugin_go "github.com/gogo/protobuf/protoc-gen-gogo/plugin"
)

func main() {
	//bs, err := ioutil.ReadFile("./activty.bs")
	//if err != nil {
	//	return
	//}
	//req := readRequest(bytes.NewReader(bs))
	req := readRequest(os.Stdin)
	writeResponse(os.Stdout, generate(req))
}

func readRequest(r io.Reader) *plugin_go.CodeGeneratorRequest {
	data, err := ioutil.ReadAll(r)
	if err != nil {
		panic(err)
	}
	//ioutil.WriteFile("activty.bs", data, 0644)

	req := new(plugin_go.CodeGeneratorRequest)
	if err = proto.Unmarshal(data, req); err != nil {
		panic(err)
	}

	if len(req.FileToGenerate) == 0 {
		panic(err)
	}

	return req
}

func generate(in *plugin_go.CodeGeneratorRequest) *plugin_go.CodeGeneratorResponse {
	resp := &plugin_go.CodeGeneratorResponse{}

	gen := gogogen.New()
	gen.Request = in
	gen.WrapTypes()
	gen.SetPackageNames()
	gen.BuildTypeNameMap()
	for _, f := range in.GetProtoFile() {
		// skip google/protobuf/timestamp, we don't do any special serialization for jsonpb.
		if *f.Name == "google/protobuf/timestamp.proto" {
			continue
		}
		// generate service only
		if f.Service == nil {
			continue
		}
		cf, err := generator.CreateClientAPI(f, gen)
		if err != nil {
			resp.Error = proto.String(err.Error())
			return resp
		}

		resp.File = append(resp.File, cf)
	}

	//resp.File = append(resp.File, generator.RuntimeLibrary())

	return resp
}

func writeResponse(w io.Writer, resp *plugin_go.CodeGeneratorResponse) {
	data, err := proto.Marshal(resp)
	if err != nil {
		panic(err)
	}
	_, err = w.Write(data)
	if err != nil {

	}
	//ioutil.WriteFile("activty.test.swift", data, 0644)
}

type Params map[string]string

func getParameters(in *plugin_go.CodeGeneratorRequest) Params {
	params := make(Params)

	if in.Parameter == nil {
		return params
	}

	pairs := strings.Split(*in.Parameter, ",")

	for _, pair := range pairs {
		kv := strings.Split(pair, "=")
		params[kv[0]] = kv[1]
	}

	return params
}
