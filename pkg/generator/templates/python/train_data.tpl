{{ define "train_data" }}
import glob
import pandas as pd
import numpy as np
import tensorflow as tf

CSV_COLUMN_NAMES = [{{ .Features.QuotedVars }}, "{{ pascalCase .Classifier.Name }}"]

INPUT_TENSOR_NAME = 'inputs'

TRAIN_PATH = '{{ .TrainPath }}'
TEST_PATH = '{{ .TestPath }}'

TRAIN_FILES = glob.glob(TRAIN_PATH)
TEST_FILES = glob.glob(TEST_PATH)

def get_feature_columns():
    {{ range .Features }}
    {{ if eq .FeatType "float" }}{{ .ParamsStructName }} = tf.feature_column.numeric_column("{{ .ParamsStructName }}"){{end}}
    {{ if eq .FeatType "category" }}{{ .ParamsStructName }} = tf.feature_column.indicator_column(tf.feature_column.categorical_column_with_identity(key='{{ .ParamsStructName }}', num_buckets={{ .NumBuckets }}, default_value={{ .Default }})){{ end }}
    {{ if eq .FeatType "boolean" }}{{ .ParamsStructName }} = tf.feature_column.indicator_column(tf.feature_column.categorical_column_with_vocabulary_list(key='{{ .ParamsStructName }}', vocabulary_list=[0, 1])){{ end }}
    {{ end }}
    # Represent a 10-element vector in which each cell contains a tf.float32.
    # vector_feature_column = tf.feature_column.numeric_column(key="Bowling", shape=10)
    # Represent a 10x5 matrix in which each cell contains a tf.float32.
    # matrix_feature_column = tf.feature_column.numeric_column(key="MyMatrix", shape=[10,5])
    # hashed_feature_column = tf.feature_column.categorical_column_with_hash_bucket(key = "some_feature", hash_bucket_size = 100) # The number of categories
    return [{{ .Features.NamedVars }}]

def eval_input_fn(features, labels, batch_size):
    """An input function for evaluation or prediction"""
    features=dict(features)
    if labels is None:
        # No labels, use only features.
        inputs = features
    else:
        inputs = (features, labels)

    # Convert the inputs to a Dataset.
    dataset = tf.data.Dataset.from_tensor_slices(inputs)

    # Batch the examples
    assert batch_size is not None, "batch_size must not be None"
    dataset = dataset.batch(batch_size)

    # Return the dataset.
    return dataset

def csv_eval_fn(csv_path, batch_size):
    # Create a dataset containing the text lines.
    dataset = tf.data.TextLineDataset(csv_path)

    # Parse each line.
    dataset = dataset.map(_parse_line)

    # Batch the examples
    assert batch_size is not None, "batch_size must not be None"
    dataset = dataset.batch(batch_size)

    # Return the dataset.
    return dataset




# The remainder of this file contains a simple example of a csv parser,
#     implemented using a the `Dataset` class.

# `tf.parse_csv` sets the types of the outputs to match the examples given in
#     the `record_defaults` argument.
CSV_TYPES = [{{ range .Features}}{{ .Placeholder }}, {{ end }}{{ .Classifier.Placeholder }}]

def _parse_line(line):
    # Decode the line into its fields
    fields = tf.decode_csv(line, record_defaults=CSV_TYPES)

    # Pack the result into a dictionary
    features = dict(zip(CSV_COLUMN_NAMES, fields))

    # Separate the label from the features
    label = features.pop('{{ pascalCase .Classifier.Name }}')

    return features, label


def csv_input_fn(csv_path, batch_size):
    print(csv_path)
    # Create a dataset containing the text lines.
    dataset = tf.data.TextLineDataset(csv_path)

    # Parse each line.
    dataset = dataset.map(_parse_line)

    print(csv_path)

    # Shuffle, repeat, and batch the examples.
    dataset = dataset.shuffle(1000).repeat().batch(batch_size)

    # Return the dataset.
    return dataset
{{ end }}