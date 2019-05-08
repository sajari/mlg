package models

import (
	"fmt"
	"path/filepath"
	"strings"

	"code.sajari.com/mlg/pkg/features"
	"code.sajari.com/mlg/pkg/generator"
	"code.sajari.com/mlg/pkg/lang"
	"code.sajari.com/mlg/pkg/path"
)

func (d *TensorflowModel) trainCmd(p path.Pkg, tp, mp, name string) string {
	bp, _ := filepath.Abs(string(p))
	tp, _ = filepath.Abs(tp)
	mp, _ = filepath.Abs(mp)
	return fmt.Sprintf("docker run -it --rm -v %[1]s:/tmp -v %[2]s:%[2]s -v %[3]s:%[3]s -w /tmp tensorflow/tensorflow python ./%[4]s.py", bp, tp, mp, name)
}

type TensorflowModel struct {
	Model               `yaml:",inline"`
	Checkpoint          int     `yaml:"checkpoint"`
	CheckpointSaveSteps int     `yaml:"save-steps"`
	BatchSize           int     `yaml:"batch-size"`
	TrainSteps          int     `yaml:"train-steps"`
	HiddenUnits         Network `yaml:"hidden-units"`
}

type Network []int

func (n Network) String() string {
	var str string
	for _, s := range n {
		str += fmt.Sprintf("%d, ", s)
	}
	return strings.TrimSuffix(str, ", ")
}

func (d *TensorflowModel) ImportPath(p path.Base) string {
	return generator.GoImportPath(p, d.Name)
}

func (d *TensorflowModel) Data(p path.Base, f *features.YAML) (map[string]interface{}, error) {
	data, err := d.Model.Data(p, f)
	if err != nil {
		return nil, err
	}
	data["Model"] = d

	return data, nil
}

func (d *TensorflowModel) Generator(p path.Base, f *features.YAML) generator.Generator {
	data, err := d.Data(p, f)
	if err != nil {
		return nil
	}

	fns := features.UtilityFuncs()
	pkg := p.PkgPath(d.Name)

	// Print training instructions for tensorflow:
	fmt.Printf("To train model: %s\n\n%s\n\n\n", d.Name, d.trainCmd(pkg, filepath.Dir(f.TrainPath), filepath.Dir(d.ModelDir), d.Name))

	// Return the templates
	return generator.MultiGenerator{
		d.dataGenerator(p, data),
		&generator.Skeleton{ // TODO: this is only for classification currently
			Template: "train_data",
			Path:     pkg.Filename("train_data", lang.Python),
			Lang:     lang.Python,
			Data:     data,
			Funcs:    fns,
		},
	}
}

// Generate files for tensorflow based test, train and serve commands
// func (d *TensorflowModel) TFGenerators(p path.Base, f *features.YAML) generator.Generator {

// }
