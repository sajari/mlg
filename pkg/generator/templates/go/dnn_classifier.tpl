{{ define "dnn_classifier" }}
// Code generated.  DO NOT EDIT.
package {{ .Name }} 

import (
	"fmt"

	"github.com/golang/protobuf/proto"

	tf "github.com/tensorflow/tensorflow/tensorflow/go"

	pb "code.sajari.com/mlg/pkg/proto"

	"{{ .FeatPkgPath }}"
)

type TensorflowModel struct{
	*tf.SavedModel
}

func (m *TensorflowModel) Predict(dp *features.DataPoint) (interface{}, error) {
	fs := make(map[string]*pb.Feature, features.Length)
	for i, p := range *dp {
		fs[features.Fields()[i]] = &pb.Feature{
			Kind: &pb.Feature_FloatList{
				FloatList: &pb.FloatList{
					Value: []float32{float32(p)},
				},
			},
		}
		switch dp.TypeFromOffset(i) {
		case features.Float:
			fs[features.Fields()[i]] = &pb.Feature{
				Kind: &pb.Feature_FloatList{
					FloatList: &pb.FloatList{
						Value: []float32{float32(p)},
					},
				},
			}
		case features.Integer, features.Bool: 
			fs[features.Fields()[i]] = &pb.Feature{
				Kind: &pb.Feature_Int64List{
					Int64List: &pb.Int64List{
						Value: []int64{int64(p)},
					},
				},
			}
		}
		
	}

	pro := pb.Example{
		Features: &pb.Features{
			Feature: fs,
		},
	}

	msg, err := proto.Marshal(&pro)
	if err != nil {
		return nil, err
	}

	in, err := tf.NewTensor([]string{string(msg)})
	if err != nil {
		return nil, err
	}
	output, err := m.Session.Run(
		map[tf.Output]*tf.Tensor{
			m.Graph.Operation("input_example_tensor").Output(0): in,
		},
		[]tf.Output{
			m.Graph.Operation("dnn/head/predictions/probabilities").Output(0),
		},
		nil)
	if err != nil {
		return nil, err
	}
	return output[0].Value(), nil
}

func ServeTensorflowClassifier(path string) (*TensorflowModel, error) {
	fmt.Println("Serving DNN Classifier using Tensorflow version: ", tf.Version())

	model, err := tf.LoadSavedModel(path, []string{"serve"}, nil)
	if err != nil {
		return nil, err
	}

	return &TensorflowModel{model}, nil 
}

{{ end }}
