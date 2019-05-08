package lang

type Language int

const (
	_ Language = iota
	Python
	Go
)

func (l Language) String() string {
	switch l {
	case Python:
		return "python"
	case Go:
		return "go"
	}
	return "unknown"
}

func (l Language) Extension() string {
	switch l {
	case Python:
		return "py"
	case Go:
		return "go"
	}
	return "unknown"
}
