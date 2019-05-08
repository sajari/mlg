{{ define "xgb_ranker" }}
// Code generated.  DO NOT EDIT.
package {{ .Name }} 

import (
    "github.com/dmitryikh/leaves"

    "{{ .FeatPkgPath }}"
)

type XGBRanker struct{
	*leaves.Ensemble
}

func ServeXGBRanker(path string) (*XGBRanker, error) {
    m, err := leaves.XGEnsembleFromFile(path)
	if err != nil {
		return nil, err
	}
    return &XGBRanker{m}, nil 
}

// Predict wraps the model output to produce ranking score for the datapoints
func (m *XGBRanker) Predict(dps []features.DataPoint) []float64 {
    ps := make([]float64, len(dps))
	for i, dp := range dps {
        ps[i] = m.Ensemble.PredictSingle(dp, m.NEstimators())
		
    }
    return ps
}

{{ end }}
