{{ define "dnn_classifier_accuracy" }}
// Code generated.  DO NOT EDIT.
package main

import (
	"encoding/csv"
	"fmt"
	"io"
	"log"
	"os"
	"strconv"
	"path/filepath"

	dnn "{{ .ThisPkgPath }}"

	"{{ .FeatPkgPath }}"
)

const (
	testPath  = "{{ .TestPath }}"
)

var(    
	modelPath = "{{ .ModelAbsPath }}"
    classes = []string{ {{ .Classifier.QuotedStringArray }} }
)

func main() {
	modelNum := 0
	modelVersion := ""
	err := filepath.Walk(modelPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			log.Fatal(err)
		}
		if info.IsDir() {
			val, err := strconv.Atoi(info.Name())
			if err != nil {
				return nil
			}
			if val > modelNum {
				modelVersion = info.Name()
				modelNum = val
			}
		}
		return nil
	})
	if err != nil {
		log.Fatal(err)
	}

	modelPath = filepath.Join(modelPath, modelVersion)

	m, err := dnn.ServeTensorflowClassifier(modelPath)
	if err != nil {
		log.Fatal(err)
	}

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
		result, err := m.Predict(&dp)
		if err != nil {
			log.Fatal(err)
		}
		var max float32
		var class int
		probabilities := result.([][]float32)[0]
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