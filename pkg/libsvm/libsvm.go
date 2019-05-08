package libsvm

import (
	"bufio"
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"strings"
	"time"
)

// SuperSet contains data that can be serialised to
// the libsvm file format
type superSet struct {
	Lookup map[string]int
	Sets   []*Set
}

func NewSuperSet() *superSet {
	return &superSet{
		Lookup: make(map[string]int),
		Sets:   make([]*Set, 0, 10),
	}
}

func (ss *superSet) Add(id string, rs ...*Result) {
	for _, r := range rs {
		for _, s := range ss.Sets {
			if s.ID == id {
				s.Results = append(s.Results, r)
				return
			}
		}
		ss.Sets = append(ss.Sets, &Set{
			ID: id,
			Results: []*Result{
				r,
			},
		})
	}
}

type Set struct {
	ID      string
	Results []*Result
}

type Result struct {
	Score    float64
	Features map[int]float64
	Comments [][2]string
}

func FromLibSVM(filename string, header bool) (*superSet, error) {
	ss := NewSuperSet()

	f, err := os.Open(filename)
	if err != nil {
		return ss, err
	}

	var groups []int
	var numInGroup int
	fg, err := os.Open(fmt.Sprintf("%s.group", filename))
	if err == nil {
		scg := bufio.NewScanner(fg)
		for scg.Scan() {
			g, err := strconv.Atoi(scg.Text())
			if err != nil {
				continue
			}
			groups = append(groups, g)
		}
		numInGroup = groups[0] // first group size
	}

	sc := bufio.NewScanner(f)

	var id string // need a new set when id changes
	var groupOffset int
	for sc.Scan() {
		res := &Result{
			Features: make(map[int]float64),
			Comments: make([][2]string, 0),
		}
		pieces := strings.Split(sc.Text(), " ")
		var inComments bool
		if len(groups) > 0 {
			id = strconv.Itoa(groupOffset)
			numInGroup--
			if numInGroup == 0 && groupOffset < len(groups)-1 {
				groupOffset++
				numInGroup = groups[groupOffset]
			}
		}

		for i, p := range pieces {
			if p == "" {
				continue
			}

			switch {
			case i == 0:
				fl, err := strconv.ParseFloat(p, 64)
				if err != nil {
					return ss, err
				}
				res.Score = fl

			case (i == 1 && len(groups) == 0) || strings.Contains(p, "qid"): // If there is no group file, the first item is the qid, unless both exist
				pp := strings.Split(p, ":")
				id = pp[1]

			case p == "#":
				inComments = true

			default: // Either a feature pair or a comment pair
				pp := strings.Split(p, ":")
				if inComments {
					res.Comments = append(res.Comments, [2]string{pp[0], pp[1]})
				} else {
					fk, err := strconv.Atoi(pp[0])
					if err != nil {
						return ss, err
					}
					fv, err := strconv.ParseFloat(pp[1], 64)
					if err != nil {
						return ss, err
					}
					res.Features[fk] = fv
				}
			}

		}
		ss.Add(id, res)
	}
	return ss, nil
}

func (ss superSet) LibSVM(filename string, comments bool) error {
	fout, err := os.Create(filename)
	if err != nil {
		return err
	}
	fgroup, err := os.Create(filename + ".group")
	if err != nil {
		return err
	}

	for i, s := range ss.Sets {
		fgroup.WriteString(fmt.Sprintf("%d\n", len(s.Results)))
		for _, r := range s.Results {
			var fsStr, csStr []string
			for j := 0; j < len(r.Features); j++ {
				if f, ok := r.Features[j]; ok {
					fsStr = append(fsStr, fmt.Sprintf("%d:%.4f", j, f))
				}
			}

			if comments {
				for _, c := range r.Comments {
					csStr = append(csStr, fmt.Sprintf("%s:%s", c[0], c[1]))
				}
			}
			fout.WriteString(fmt.Sprintf("%.3f qid:%d %s %s\n", r.Score, i+1, strings.Join(fsStr, " "), strings.Join(csStr, " ")))
		}

	}
	fout.Close()
	fgroup.Close()
	return nil
}

// Split uses a random ratio to split a superSet into a train and test
// set. The percent is the proportion dedicated to the first superSet
// represented as an int out of 100. The non training portion is split between
//
func (ss *superSet) Split(percent int) (*superSet, *superSet, *superSet) {
	train := NewSuperSet()
	test := NewSuperSet()
	valid := NewSuperSet()
	rand.Seed(time.Now().UnixNano())
	for _, s := range ss.Sets {
		random := rand.Intn(100)
		if random < percent {
			for _, r := range s.Results {
				train.Add(s.ID, r)
			}
		} else {
			for _, r := range s.Results {
				if random%2 == 0 {
					test.Add(s.ID, r)
				} else {
					valid.Add(s.ID, r)
				}
			}
		}

	}
	return train, test, valid
}
