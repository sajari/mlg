{{ define "xgb_classifier_accuracy" }}
// Code generated.  DO NOT EDIT.
package main

import (
	"encoding/csv"
	"fmt"
	"io"
	"log"
	"os"
	"strconv"

	"{{ .FeatPkgPath }}"
	"{{ .ThisPkgPath }}"
)

const (
	testPath  = "{{ .TestPath }}"
)

var(    
	modelPath = "{{ .ModelAbsPath }}"
    classes = []string{ {{ .Classifier.QuotedStringArray }} }
)

func main() {
	m, err := {{ .Name }}.ServeXGBClassifier(modelPath)
	if err != nil {
		panic(err)
	}

	fmt.Printf("Classes: %v\n", m.NClasses())
	fmt.Printf("Estimators: %v\n", m.NEstimators())
	fmt.Printf("Features: %v\n", m.NFeatures())
	fmt.Printf("Name: %v\n", m.Name())

	f, err := os.Open(testPath)
	if err != nil {
		log.Fatal(err)
	}

	correct := make([]int, len(classes))
	incorrect := make([]int, len(classes))

	cr := csv.NewReader(f)
	for {
		record, err := cr.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			log.Fatal(err)
		}
		dp := features.NewDataPoint()
		dp.PopulateFromRow(record)

		// fmt.Printf("dp: %v\n", dp)
		probabilities, err := m.Predict(dp)
		if err != nil {
			log.Fatal(err)
		}
		var max float64
		var class int
		for i, prediction := range probabilities {
			if prediction > max {
				max = prediction
				class = i
			}
		}
		val, err := strconv.Atoi(record[features.Length])
		if err != nil {
			fmt.Printf("failed to parse actual result: %v\n", err)
			continue
		}
		// fmt.Printf("probs: %v (%v)\n\n", probabilities, val)
		if class == val {
			correct[val]++
		} else {
			incorrect[val]++
		}
	}
	for i := 0; i < len(classes); i++ {
		fmt.Printf("%v: correct: %d incorrect: %d ratio: %.2f\n", classes[i], correct[i], incorrect[i], float32(correct[i])/(float32(correct[i])+float32(incorrect[i])))
	}
}

{{ end }}