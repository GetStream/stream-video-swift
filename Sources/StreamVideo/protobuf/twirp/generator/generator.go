package generator

import (
	"github.com/gogo/protobuf/protoc-gen-gogo/descriptor"
	"path"
)

func dartModuleFilename(f *descriptor.FileDescriptorProto) string {
	return twirpFilename(*f.Package,*f.Name)
}

func dartFilename(name string) string {
	if ext := path.Ext(name); ext == ".proto" || ext == ".protodevel" {
		base := path.Base(name)
		name = base[:len(base)-len(path.Ext(base))]
	}

	name += ".model.swift"

	return name
}

func twirpFilename(prefix, fullPath string) string {
	name := ""
	if ext := path.Ext(fullPath); ext == ".proto" || ext == ".protodevel" {
		base := path.Base(fullPath)
		name = base[:len(base)-len(path.Ext(base))]
	}
	name = prefix+"."+name
	name += ".twirp.swift"
	return path.Join(path.Dir(fullPath), name)
}
