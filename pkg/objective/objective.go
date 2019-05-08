package objective

type Template string

const (
	Classifier Template = "classifier"
	Regressor  Template = "regressor"
	Ranker     Template = "ranker"
	Features   Template = "features"
)
