package path

import (
	"fmt"
	"path/filepath"

	"code.sajari.com/mlg/pkg/lang"
)

type Base string

func BasePath(path string) Base {
	return Base(path)
}

type Pkg string

func (p Base) PkgPath(name string) Pkg {
	return Pkg(filepath.Join(string(p), "pkg", name))
}

func (p Pkg) Filename(name string, l lang.Language) string {
	return filepath.Join(string(p), fmt.Sprintf("%s.%s", name, l.Extension()))
}

type Cmd string

func (p Base) CmdPath(name string) Cmd {
	return Cmd(filepath.Join(string(p), "cmd", name))
}

func (p Cmd) Filename(name string, l lang.Language) string {
	return filepath.Join(string(p), name, fmt.Sprintf("%s.%s", name, l.Extension()))
}
