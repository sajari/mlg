{{ define "xgb_regressor_accuracy" }}
// Code generated.  DO NOT EDIT.
package main

import (
	"encoding/csv"
	"fmt"
	"io"
	"log"
	"os"
	"math"
	"strconv"

	"gonum.org/v1/gonum/stat"
	
	"{{ .FeatPkgPath }}"
	"{{ .ThisPkgPath }}"
)

const (
	testPath  = "{{ .TestPath }}"
)

var(    
	modelPath = "{{ .ModelAbsPath }}"
)

func RMSE(predicted, observed []float64) float64 {
	var sqs float64
	for i, p := range predicted {
		sqs += math.Pow(p - observed[i], 2)
	}
	return math.Sqrt(sqs / float64(len(predicted)))
}

func main() {
	m, err := {{ .Name }}.ServeXGBRegressor(modelPath)
	if err != nil {
		panic(err)
	}

	fmt.Printf("Estimators: %v\n", m.NEstimators())
	fmt.Printf("Features: %v\n", m.NFeatures())
	fmt.Printf("Name: %v\n", m.Name())

	f, err := os.Open(testPath)
	if err != nil {
		log.Fatal(err)
	}

	var predictions, observed []float64

	dp := features.NewDataPoint()
	cr := csv.NewReader(f)
	for {
		record, err := cr.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			log.Fatal(err)
		}
		dp.PopulateFromRow(record)

		predicted := m.Predict(dp)

		obs, err := strconv.ParseFloat(record[features.Length], 64)
		if err != nil {
			log.Fatal(err)
		}
		predictions = append(predictions, predicted)
		observed = append(observed, obs)

		// fmt.Printf("Predicted: %.4f Actual: %.4f Error: %.4f\n", predicted, obs, obs-predicted)

	}

	R2 := stat.RSquaredFrom(predictions, observed, nil)
	fmt.Printf("R2 = %.4f\n", R2)
	fmt.Printf("RMSE = %.4f", RMSE(predictions, observed))

}

{{ end }}