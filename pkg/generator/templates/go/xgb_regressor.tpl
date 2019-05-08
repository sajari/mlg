{{ define "xgb_regressor" }}
// Code generated.  DO NOT EDIT.
package {{ .Name }} 

import (
    "github.com/dmitryikh/leaves"

	"{{ .FeatPkgPath }}"
)

type XGBRegressor struct{
	*leaves.Ensemble
}

func ServeXGBRegressor(path string) (*XGBRegressor, error) {
    m, err := leaves.XGEnsembleFromFile(path)
	if err != nil {
		return nil, err
	}
    return &XGBRegressor{m}, nil 
}

// Predict wraps the model output to produce a prediction for the input datapoint
func (m *XGBRegressor) Predict(dp features.DataPoint) float64 {
    return m.Ensemble.PredictSingle(dp, m.NEstimators())
}

{{ end }}
