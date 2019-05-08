{{ define "dnn_classifier" }}
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import argparse
import tensorflow as tf
import train_data

# Change maximum number checkpoints to {{ .Model.Checkpoint }}
run_config = tf.estimator.RunConfig()
run_config = run_config.replace(keep_checkpoint_max={{ .Model.Checkpoint }}, save_checkpoints_steps={{ .Model.CheckpointSaveSteps }})


parser = argparse.ArgumentParser()
parser.add_argument('--batch_size', default={{ .Model.BatchSize }}, type=int, help='batch size')
parser.add_argument('--train_steps', default={{ .Model.TrainSteps }}, type=int,
                    help='number of training steps')
parser.add_argument('--export_dir_base', default="{{ .ModelAbsPath }}", type=str, help='location to export the model')


def main(argv):
    args = parser.parse_args(argv[1:])

    # Feature cols
    feature_cols = train_data.get_feature_columns()

    # Build hidden layer DNN
    classifier = tf.estimator.DNNClassifier(
        model_dir="{{ .ModelAbsPath }}",
        feature_columns=feature_cols,
        hidden_units=[{{ .Model.HiddenUnits }}],
        config=run_config,
        # Activation function replace default
        # activation_fn=tf.nn.celu,
        n_classes={{ len .Classifier.Classes }})

    # Train the Model.
    classifier.train(
        input_fn=lambda:train_data.csv_input_fn(train_data.TRAIN_FILES, args.batch_size),
        steps=args.train_steps)

    # Evaluate the model.
    eval_result = classifier.evaluate(
        input_fn=lambda:train_data.csv_eval_fn(train_data.TEST_FILES, args.batch_size))

    print('\nTest set accuracy: {accuracy:0.3f}\n'.format(**eval_result))

    # Export the serving component
    feature_spec = tf.feature_column.make_parse_example_spec(feature_cols)
    serving_input_receiver_fn = tf.estimator.export.build_parsing_serving_input_receiver_fn(
        feature_spec,
        default_batch_size=None
    )
    classifier.export_savedmodel(args.export_dir_base, serving_input_receiver_fn)

if __name__ == '__main__':
    tf.logging.set_verbosity(tf.logging.INFO)
    tf.app.run(main)
{{ end }}