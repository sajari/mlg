package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"

	"code.sajari.com/mlg/pkg/features"
	"code.sajari.com/mlg/pkg/lang"
	"code.sajari.com/mlg/pkg/models"
	"code.sajari.com/mlg/pkg/path"

	yaml "gopkg.in/yaml.v2"
)

var (
	inputPath  = flag.String("input", "", "path to YAML file containing features and models YAML files")
	outputPath = flag.String("output", "", "path to save generated output code")
)

func failf(pattern string, args ...interface{}) {
	fmt.Printf(pattern, args...)
	os.Exit(1)
}

func parseYAML(path string, target interface{}) {
	f, err := os.Open(path)
	if err != nil {
		failf("Could not open YAML file: %v", err)
	}
	defer f.Close()

	b, err := ioutil.ReadAll(f)
	if err != nil {
		failf("Could not read data from YAML file %q: %v", path, err)
	}

	if err := yaml.Unmarshal(b, target); err != nil {
		failf("Could not unmarshal YAML file %q: %v", path, err)
	}
}

func main() {
	flag.Parse()

	if *inputPath == "" {
		failf("-input must not be empty")
	}

	if *outputPath == "" {
		failf("-output must not be empty amd must be a non-relative path")
	}

	// Extract
	fs := &features.YAML{}
	featuresPath := filepath.Join(*inputPath, "features.yaml")
	parseYAML(featuresPath, fs)

	ms := &models.YAML{}
	modelsPath := filepath.Join(*inputPath, "models.yaml")
	parseYAML(modelsPath, ms)

	// TODO: test compatibility

	p := path.BasePath(*outputPath)
	fgn := fs.Generator(p, lang.Go, fs)
	if err := fgn.Generate(); err != nil {
		failf("template generation error: %v", err)
	}

	mgn := ms.Generate(*outputPath, fs)
	if err := mgn.Generate(); err != nil {
		failf("template generation error: %v", err)
	}
}
