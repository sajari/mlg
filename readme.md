# mlg
This package bypasses the difficulties in writing code to sync models written in Python (Tensorflow, XGBoost, etc) with serving code written in Go. Instead features and model definitions are described in YAML and the corresponding code is then automatically generated for model training, testing and serving. This binds the features definition to the model code and eliminates errors associated with writing code in two languages. 

The `cmd/mlg` command automatically generates a feature pkg (Go), training pkgs (Go and/or Python) and prediction pkg (Go) from provided `features.yaml` and `models.yaml` files. 

Note: If no models are specified, the feature pkg can still be generated, which creates a Go `features` pkg to create and define data points for usage in models. 

### Dependencies
Download XGBoost for Python. See [instructions here](https://xgboost.readthedocs.io/en/latest/build.html)

For neural networks you need Tensorflow and Docker (not essential, but much easier to manage). Make sure you have Tensorflow:
```
go get -u github.com/tensorflow/tensorflow/tensorflow/go
```

Download the Tensorflow Docker image:
```
docker pull tensorflow/tensorflow 
```

### Install the `mlg` command:
```
cd cmd/mlg/
go install
```

### What does the `mlg` command do?

1. `mlg` parses YAML files in the <input> flag specified path and generates corresponding code files in the <output> flag specified path
2. It also prints an example entry point for training the models (if applicable)

At this point you should be able to train the models and test them directly from the generated Go code also. 

### Iris example (Tensorflow DNN and XGBoost classifiers)
Dataset from: https://archive.ics.uci.edu/ml/datasets/iris

To run this example:

1. Download the data, unzip and generate the features, model training and serving code using the `mlg` command
```
cd examples/iris
curl -SL https://cdn.sajari.com/datasets/iris/iris.zip | tar -xz - -C .
mlg --input=./ --output=code/
```

This will read the `features.yaml` and `models.yaml` from the current directory and generate several files in the `code` directory. 

2. A training command for Tensorflow will be printed from the `mlg` generating step. Run it to create your model in a Docker container, which will be saved back to your local drive. 
3. To test the DNN Tensorflow model using Go, run:
```
go run code/cmd/dnn/dnn_classifier_accuracy/dnn_classifier_accuracy.go
```

4. To train the XGBoost model:
```
python code/pkg/xgb/xgb.py
```

5. To test the XGBoost model using Go:
```
go run code/cmd/xgb/xgb_classifier_accuracy/xgb_classifier_accuracy.go
```

### Wine example (XGBoost regressor)
Dataset from: https://archive.ics.uci.edu/ml/datasets/wine+quality 
P. Cortez, A. Cerdeira, F. Almeida, T. Matos and J. Reis. 
Modeling wine preferences by data mining from physicochemical properties. In Decision Support Systems, Elsevier, 47(4):547-553, 2009.

To run this example:

1. Download the data, unzip and generate the features, model training and serving code using the `mlg` command
```
cd examples/wine
curl -SL https://cdn.sajari.com/datasets/wine/wine.zip | tar -xz - -C .
mlg --input=./ --output=code/
```

2. To train the XGBoost model:
```
python code/pkg/xgb/xgb.py
```

3. To test the XGBoost model using Go:
```
go run code/cmd/xgb/xgb_regressor_accuracy/xgb_regressor_accuracy.go
```

### Learn to rank (LTR) example (XGBoost ranker)
Dataset from: https://arxiv.org/abs/1306.2597 
XGBoost code sampled from: https://github.com/dmlc/xgboost/tree/master/demo/rank

1. Download the data, unzip and generate the features, model training and serving code using the `mlg` command

```
cd examples/ranking
curl -SL https://cdn.sajari.com/datasets/mq2008/mq2008.zip | tar -xz - -C .
mlg --input=./ --output=code/
```

2. To train the XGBoost model:
```
python code/pkg/xgb/xgb.py
```

3. To test the XGBoost model using Go:
```
go run code/cmd/xgb/xgb_ranker_accuracy/xgb_ranker_accuracy.go
```



### Troubleshooting:
- If using Docker on OSX for model training, the paths for models and training files must exist in the Docker shared folders settings or they cannot be mounted and written to.
- If using a local environment to run the Go serving, the Tensorflow version needs to match. Note: this is not the locally installed version, but rather the C library installed from: https://www.tensorflow.org/install/lang_c
- Only specific feature column types are available currently, but this can easily be extended. 


#### todo
- Add other feature types
- Fix serving code to use github.com/sajari/storage pkg
- Check features fit model signatures before allowing them to be created
- Convert text classes into numeric (possibly another cmd? Needs to match python and go)
- Export model to gs:// or similar for import with serving code

