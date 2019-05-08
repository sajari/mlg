package models

import (
	"fmt"
	"os"
	"path/filepath"

	"code.sajari.com/mlg/pkg/features"
	"code.sajari.com/mlg/pkg/generator"
	"code.sajari.com/mlg/pkg/lang"
	"code.sajari.com/mlg/pkg/objective"
	"code.sajari.com/mlg/pkg/path"
)

type Model struct {
	Name     string                 `yaml:"name"`
	Template objective.Template     `yaml:"template"`
	ModelDir string                 `yaml:"model-dir"`
	Config   map[string]interface{} `yaml:"config"`
}

type YAML struct {
	Tensorflow []*TensorflowModel `yaml:"tensorflow"`
	XGBoost    []*Model           `yaml:"xgboost"`
}

func (y YAML) Generate(p string, f *features.YAML) generator.Generator {
	var gns generator.MultiGenerator
	for _, d := range y.Tensorflow {
		gns = append(gns, d.Generator(path.BasePath(p), f))
	}
	for _, d := range y.XGBoost {
		gns = append(gns, d.Generator(path.BasePath(p), f))
	}
	return gns
}

func (x *Model) ImportPath(p path.Base) string {
	return generator.GoImportPath(p, x.Name)
}

func (x *Model) Data(p path.Base, f *features.YAML) (map[string]interface{}, error) {
	trainAbs, err := filepath.Abs(f.TrainPath)
	if err != nil {
		return nil, fmt.Errorf("could not get abs path for TrainPath")
	}
	testAbs, err := filepath.Abs(f.TestPath)
	if err != nil {
		return nil, fmt.Errorf("could not get abs path for TestPath")
	}
	modelAbs, err := filepath.Abs(x.ModelDir)
	if err != nil {
		return nil, fmt.Errorf("could not get abs path for ModelDir")
	}
	os.MkdirAll(filepath.Dir(modelAbs), 0755)

	data := map[string]interface{}{
		"Name":         x.Name,
		"Config":       x.Config,
		"Features":     f.Feats,
		"TrainPath":    trainAbs,
		"TestPath":     testAbs,
		"ModelAbsPath": modelAbs,
		"FeatPkgPath":  f.Feats.ImportPath(p),
		"ThisPkgPath":  x.ImportPath(p),
	}

	if valiAbs, err := filepath.Abs(f.ValidPath); err == nil {
		data["ValidPath"] = valiAbs
	}

	switch x.Template {
	case objective.Classifier:
		data["Classifier"] = f.Classifier
	case objective.Regressor:
		data["Regressor"] = f.Regressor
	case objective.Ranker:
		data["Ranker"] = f.Ranker
	}

	return data, nil
}

func (x *Model) dataGenerator(p path.Base, data map[string]interface{}) generator.Generator {
	fns := features.UtilityFuncs()
	pkg := p.PkgPath(x.Name)
	cmd := p.CmdPath(x.Name)

	// Print training instructions:
	// fmt.Printf("To train model: %s\n\n%s\n\n\n", x.Name, trainCmd(pkg, filepath.Dir(f.TrainPath), filepath.Dir(x.ModelDir), x.Name))

	// Return the templates
	tpl := fmt.Sprintf("%s_%s", x.Name, x.Template)
	tpl_acc := fmt.Sprintf("%s_%s_accuracy", x.Name, x.Template)
	return generator.MultiGenerator{
		&generator.Skeleton{
			Template: objective.Template(tpl),
			Path:     pkg.Filename(x.Name, lang.Python),
			Lang:     lang.Python,
			Data:     data,
			Funcs:    fns,
		},
		&generator.Skeleton{
			Template: objective.Template(tpl),
			Path:     pkg.Filename(x.Name, lang.Go),
			Lang:     lang.Go,
			Data:     data,
			Funcs:    fns,
		},
		&generator.Skeleton{
			Template: objective.Template(tpl_acc),
			Path:     cmd.Filename(tpl_acc, lang.Go),
			Lang:     lang.Go,
			Data:     data,
			Funcs:    fns,
		},
	}
}

func (x *Model) Generator(p path.Base, f *features.YAML) generator.Generator {
	data, err := x.Data(p, f)
	if err != nil {
		return nil
	}

	return x.dataGenerator(p, data)
}
