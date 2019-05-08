package features

import (
	"fmt"
	"strings"
	"text/template"

	"code.sajari.com/mlg/pkg/lang"
	"code.sajari.com/mlg/pkg/objective"

	"code.sajari.com/mlg/pkg/generator"
	"code.sajari.com/mlg/pkg/path"
)

type YAML struct {
	TrainPath  string      `yaml:"train-path"`
	TestPath   string      `yaml:"test-path"`
	ValidPath  string      `yaml:"valid-path"`
	Feats      Feats       `yaml:"features"`
	Classifier *Classifier `yaml:"classifier"`
	Regressor  *Regressor  `yaml:"regressor"`
	Ranker     *Ranker     `yaml:"ranker"`
}

type Feat struct {
	Name       string `yaml:"name"`
	CodeName   string `yaml:"codeName"`
	Desc       string `yaml:"desc"`
	Default    string `yaml:"default"`
	NumBuckets int    `yaml:buckets`
	FeatType   string `yaml:"type"`
	Length     int
}

type Classifier struct {
	Name    string        `yaml:"name"`
	Classes []interface{} `yaml:"classes"`
}

type Regressor struct {
	Name string `yaml:"name"`
}

type Ranker struct {
	Name string `yaml:"name"`
}

func (c Classifier) QuotedStringArray() string {
	var str []string
	for _, s := range c.Classes {
		str = append(str, fmt.Sprintf("%q", s))
	}
	return strings.Join(str, ", ")
}

func (c Classifier) Logistic() bool {
	return len(c.Classes) <= 2
}

type Feats []*Feat

func (fs Feats) NamedVars() string {
	var str []string
	for _, f := range fs {
		str = append(str, f.ParamsStructName())
	}
	return strings.Join(str, ", ")
}

func (fs Feats) QuotedVars() string {
	var str []string
	for _, f := range fs {
		str = append(str, fmt.Sprintf("%q", f.ParamsStructName()))
	}
	return strings.Join(str, ", ")
}

func (fs Feats) ImportPath(p path.Base) string {
	return generator.GoImportPath(p, string(objective.Features))
}

func (c Classifier) Placeholder() string {
	switch c.Classes[0].(type) {
	case float32, float64:
		return "[0.0]"
	case int, string, bool:
		return "[0]"
	}
	return ""
}

func (fs Feat) Placeholder() string {
	switch fs.FeatType {
	case "float":
		return "[0.0]"
	case "integer", "boolean", "category":
		return "[0]"
	}
	return ""
}

func (fs Feat) GoType() string {
	switch fs.FeatType {
	case "float":
		return "Float"
	case "integer":
		return "Integer"
	case "string":
		return "String"
	case "boolean":
		return "Bool"
	case "category":
		return "Category"
	}
	return ""
}

type Class string

func (y *YAML) Generator(p path.Base, l lang.Language, data interface{}) *generator.Skeleton {
	return &generator.Skeleton{
		Template: objective.Features,
		Path:     p.PkgPath(string(objective.Features)).Filename(string(objective.Features), l),
		Lang:     l,
		Data:     data,
	}
}

func (f *Feat) ParamsStructName() string {
	return f.codeName()
}

func (f *Feat) codeName() string {
	if f.CodeName != "" {
		return f.CodeName
	}
	return dashToPascalCase(f.Name)
}

func upperFirst(x string) string {
	return strings.ToUpper(string(x[0])) + x[1:]
}

func dashToPascalCase(x string) string {
	xs := strings.Split(x, "-")
	if len(xs) == 1 {
		return upperFirst(x)
	}

	out := make([]string, 0, len(xs))
	for _, z := range xs {
		out = append(out, upperFirst(z))
	}
	return strings.Join(out, "")
}

func UtilityFuncs() template.FuncMap {
	return map[string]interface{}{
		"pascalCase": dashToPascalCase,
	}
}
