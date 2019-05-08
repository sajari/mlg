{{ define "feat" }}
type {{.ParamsStructName}} struct {}

func (f *{{.ParamsStructName}}) Name() string {
	return "{{.Name}}"
}
func (f *{{.ParamsStructName}}) Default() string {
	return "{{.Default}}"
}
func (f *{{.ParamsStructName}}) Desc() string {
	return "{{.Desc}}"
}
func (f *{{.ParamsStructName}}) Type() featureType {
	return {{ .GoType }}
}
{{ end }}

{{ define "features" }}
// Code generated.  DO NOT EDIT.
package features

import(
	"strconv"
)

var(
	Length = {{ len .Feats }}
)

type featureType int 

const(
	Unknown featureType = iota
	Integer 
	Float 
	String
	Bool
	Category
)

type DataPoint []float64
func NewDataPoint() DataPoint {
	return make([]float64, {{ len .Feats }})
}

{{ range $i, $f := .Feats }}
func (d DataPoint) {{.ParamsStructName}}(p float64) {
	d[{{$i}}] = p
}
{{ end }}

func (d DataPoint) TypeFromOffset(i int) featureType {
	switch i {
	{{ range $i, $f := .Feats }}
	case {{ $i }}:
		return {{ $f.GoType }}
	{{ end }}
	}
	return Unknown
}

var fields = []string{
{{ range .Feats }}"{{ .ParamsStructName }}",
{{ end }}
}
func Fields() []string {
	return fields
}

{{ range .Feats }}
{{ template "feat" . }}
{{ end }}

func (d DataPoint) PopulateFromRow(row []string) error {
	for i, _ := range d {
		// TODO: extend DataPoint to allow different types
		// switch d.Type() {
		// 	case Integer:
		// 		val, err := strconv.Atoi(row[i])
		// 		err != nil {
		// 			return err 
		// 		}
		// 	case Float: 
		// 	case String:
		// 	case Bool:
		// 	case Category:
		// }
		if row[i] == "" {
			continue
		}
		val, err := strconv.ParseFloat(row[i], 64)
		if err != nil {
			return err
		}
		d[i] = val
	}
	return nil
}
{{ end }}

