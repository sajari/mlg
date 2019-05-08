package main

import (
	"encoding/csv"
	"fmt"
	"io"
	"log"
	"math"
	"os"
	"strconv"
)

var (
	fileIn  = "xxx.train.csv"
	fileOut = "xxx-normalised.train.csv"
	normMin = 0.0
	normMax = 1.0
)

func main() {
	fin, err := os.Open(fileIn)
	if err != nil {
		log.Fatal(err)
	}
	cr := csv.NewReader(fin)

	fout, err := os.Create(fileOut)
	if err != nil {
		log.Fatal(err)
	}
	cw := csv.NewWriter(fout)

	// Get max and min for each column
	min := make(map[int]float64)
	max := make(map[int]float64)
	for {
		record, err := cr.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			log.Fatal(err)
		}
		for i, n := range record {
			val, err := strconv.ParseFloat(n, 32)
			if err != nil {
				fmt.Printf("failed to parse float: %v\n", err)
				continue
			}
			if val > max[i] {
				max[i] = val
			}
			if val < min[i] {
				min[i] = val
			}
		}
	}
	fin.Seek(0, 0) // Reset the CSV

	for {
		record, err := cr.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			log.Fatal(err)
		}
		rout := make([]string, len(record))
		for i, n := range record {
			val, err := strconv.ParseFloat(n, 32)
			if err != nil {
				fmt.Printf("failed to parse float: %v\n", err)
				continue
			}
			no := (val - min[i]) / (max[i] - min[i])
			if i == len(record)-1 {
				no = val // Class
			}
			if math.IsNaN(no) || math.IsInf(no, 0) {
				no = val // Issues normalising
			}

			rout[i] = strconv.FormatFloat(no, 'f', -1, 32)
		}
		cw.Write(rout)
	}

	cw.Flush()
	fin.Close()
	fout.Close()

}
