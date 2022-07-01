package generator

import "testing"

func TestAPIContext_ApplyMarshalFlags(t *testing.T) {
	nested := &Model{
		Name: "Nested",
	}

	bar := &Model{
		Name:       "Bar",
		CanMarshal: true,
		Fields: []ModelField{
			{
				Name:      "nested",
				Type:      nested.Name,
				IsMessage: true,
			},
		},
	}

	baz := &Model{
		Name:         "Baz",
		CanUnmarshal: true,
	}

	call := ServiceMethod{
		Name:       "Call",
		InputArg:   "bar",
		InputType:  "Bar",
		OutputType: "Baz",
	}

	s := &Service{
		Name:    "FooService",
		Package: "",
		Methods: []ServiceMethod{call},
	}

	ctx := NewAPIContext()

	ctx.AddModel(nested)
	ctx.AddModel(bar)
	ctx.AddModel(baz)
	ctx.Services = append(ctx.Services, s)

	if nested.CanMarshal == true {
		t.Error("something went wrong")
	}

	ctx.ApplyMarshalFlags()

	if nested.CanMarshal != true {
		t.Errorf("expected nested.CanMarshal to be true since it is a field in Bar")
	}
}
