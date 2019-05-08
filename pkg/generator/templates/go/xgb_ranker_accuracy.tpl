{{ define "xgb_ranker_accuracy" }}
// Code generated.  DO NOT EDIT.
package main

import (
	"fmt"
	"math"
	"sort"

	"gonum.org/v1/gonum/stat"

	"code.sajari.com/mlg/pkg/libsvm"

	"{{ .FeatPkgPath }}"
	"{{ .ThisPkgPath }}"
)

var(    
	testPath  = "{{ .TestPath }}"
	modelPath = "{{ .ModelAbsPath }}"
)

func RMSE(predicted, observed []float64) float64 {
	var sqs float64
	for i, p := range predicted {
		sqs += math.Pow(p - observed[i], 2)
	}
	return math.Sqrt(sqs / float64(len(predicted)))
}

func dcg(set []float64) float64 {
	var d float64
	for i, r := range set {
		d += float64(r) / math.Log2(float64(i+2))
	}
	return d
}

func idcg(set []float64) float64 {
	cp := make([]float64, len(set))
	for i, r := range set {
		cp[i] = r
	}
	sort.Slice(cp, func(i, j int) bool {
		return cp[i] > cp[j]
	})

	return dcg(cp)
}

func ndcg(set []float64) float64 {
	idcg := idcg(set)
	if idcg == 0 {
		return 0
	}
	return dcg(set) / idcg
}

type resultsPair struct {
	Predictions []float64 
	Observed []float64
}

func (r resultsPair) Len() int {
    return len(r.Observed)
}

func (r resultsPair) Swap(i, j int) {
	r.Observed[i], r.Observed[j] = r.Observed[j], r.Observed[i]
	r.Predictions[i], r.Predictions[j] = r.Predictions[j], r.Predictions[i]
}

func (r resultsPair) Less(i, j int) bool {
    return r.Predictions[i] > r.Predictions[j] 
}

func main() {
	m, err := {{ .Name }}.ServeXGBRanker(modelPath)
	if err != nil {
		panic(err)
	}

	fmt.Printf("Estimators: %v\n", m.NEstimators())
	fmt.Printf("Features: %v\n", m.NFeatures())
	fmt.Printf("Name: %v\n", m.Name())

	var nDCGs []float64

	ss, _ := libsvm.FromLibSVM(testPath, false)
	for _, set := range ss.Sets {
		dps := make([]features.DataPoint, len(set.Results))
		observed := make([]float64, len(set.Results))
		for i, res := range set.Results {
			fs := make([]float64, features.Length)
			for j, f := range res.Features {
				fs[j-1] = f // TODO: j-1 is ugly, but the numbered features in libsvm are always > 0
			}
			dps[i] = fs
			observed[i] = res.Score
		} 
		

		predictions := m.Predict(dps)
		pair := resultsPair{Predictions: predictions, Observed: observed}
		sort.Sort(pair)
		nDCG := ndcg(pair.Observed)
		nDCGs = append(nDCGs, nDCG)
		// fmt.Printf("nDCG  = %.4f\n", nDCG)
	}

	nDCGAvg := stat.Mean(nDCGs, nil)
	fmt.Printf("nDCG average = %.4f\n", nDCGAvg)
}

{{ end }}