package generator

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"code.sajari.com/mlg/pkg/lang"
	"code.sajari.com/mlg/pkg/objective"

	"github.com/gobuffalo/packr"
)

type Skeleton struct {
	Template objective.Template
	Path     string
	Lang     lang.Language
	Funcs    template.FuncMap
	Data     interface{}
}

func (s *Skeleton) Generate() error {
	box := packr.NewBox("templates")
	tp := template.New("").Funcs(s.Funcs)
	tp = loadFromBox(tp, box, s.Lang)

	buf := &bytes.Buffer{}
	if err := tp.ExecuteTemplate(buf, string(s.Template), s.Data); err != nil {
		return err
	}

	codeBytes := buf.Bytes()

	if s.Path != "" {
		os.MkdirAll(filepath.Dir(s.Path), 0755)
		f, err := os.Create(s.Path)
		if err != nil {
			return err
		}
		defer f.Close()
		_, err = f.Write(codeBytes)
		if err != nil {
			return err
		}
	}
	return nil
}

func loadFromBox(t *template.Template, b packr.Box, l lang.Language) *template.Template {
	if err := b.Walk(func(p string, f packr.File) error {
		if p == "" {
			return nil
		}
		var err error
		var csz int64
		if finfo, err := f.FileInfo(); err != nil {
			return err
		} else {
			if finfo.IsDir() {
				return nil
			}
			csz = finfo.Size()
		}

		if !strings.HasPrefix(p, l.Extension()) {
			return nil
		}
		name := strings.TrimSuffix(filepath.Base(p), ".tpl")

		var h = make([]byte, 0, csz)
		if h, err = b.MustBytes(p); err != nil {
			return err
		}

		var tmpl *template.Template
		if name == t.Name() {
			tmpl = t
		} else {
			tmpl = t.New(name)
		}
		_, err = tmpl.Parse(string(h))
		if err != nil {
			return err
		}
		return nil
	}); err != nil {
		fmt.Printf("error loading templates: %v", err)
	}
	return t
}
