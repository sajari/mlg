package generator

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"code.sajari.com/mlg/pkg/path"
)

type Generator interface {
	Generate() error
}

type MultiGenerator []Generator

func (m MultiGenerator) Generate() error {
	for _, g := range m {
		if err := g.Generate(); err != nil {
			return err
		}
	}
	return nil
}

func GoImportPath(p path.Base, name string) string {
	rel := p.PkgPath(name)
	abs, err := filepath.Abs(string(rel))
	if err != nil {
		fmt.Printf("failed to generate import path for pkg: %v", err)
	}
	return strings.TrimPrefix(abs, fmt.Sprintf("%s/src/", os.Getenv("GOPATH")))
}
