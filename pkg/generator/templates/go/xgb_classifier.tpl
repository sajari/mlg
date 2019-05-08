{{ define "xgb_classifier" }}
// Code generated.  DO NOT EDIT.
package {{ .Name }} 

import (
    "github.com/dmitryikh/leaves"
	"github.com/dmitryikh/leaves/util"

	"{{ .FeatPkgPath }}"
)

type XGBClassifier struct{
	*leaves.Ensemble
}

func ServeXGBClassifier(path string) (*XGBClassifier, error) {
    m, err := leaves.XGEnsembleFromFile(path)
	if err != nil {
		return nil, err
	}
    return &XGBClassifier{m}, nil 
}

// Predict wraps the model output to produce a set of probabilities for the 
// classes provided to the model. If the model is binary logistic, the single 
// output is converted into a probabilities output for the [0,1] classes
func (m *XGBClassifier) Predict(dp features.DataPoint) ([]float64, error) {
	if m.NClasses() == 1 {
        // One group logistic?
        p := m.Ensemble.PredictSingle(dp, m.NEstimators())
		p = util.Sigmoid(p)
        return []float64{p, 1-p}, nil
    }
    ps := make([]float64, m.NClasses())
    err := m.Ensemble.Predict(dp, m.NEstimators(), ps)
    if err != nil {
        return nil, err
    }
    util.SigmoidFloat64SliceInplace(ps)
    return ps, nil
}

{{ end }}
