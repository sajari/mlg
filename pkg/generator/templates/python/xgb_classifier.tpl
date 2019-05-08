{{ define "xgb_classifier" }}
import xgboost as xgb
import pandas as pd
import sklearn.metrics as metrics

CSV_COLUMN_NAMES = [{{ .Features.QuotedVars }}, "{{ pascalCase .Classifier.Name }}"]
TRAIN_PATH = '{{ .TrainPath }}'
TEST_PATH = '{{ .TestPath }}'

trainData = pd.read_csv(TRAIN_PATH, header=None, names=CSV_COLUMN_NAMES)
testData  = pd.read_csv(TEST_PATH, header=None, names=CSV_COLUMN_NAMES)

trainLabels = trainData.pop('{{ pascalCase .Classifier.Name }}')
testLabels = testData.pop('{{ pascalCase .Classifier.Name }}')

# train the model
gbm = xgb.XGBClassifier(
        {{ range $k, $v := .Config }}{{ $k }} = {{ printf "%#v" $v }}, 
        {{ end }}
        ).fit(trainData, trainLabels)

# make prediction
preds = gbm.predict(testData)

accuracy = metrics.accuracy_score(testLabels, preds)
print("Accuracy: %.2f%%" % (accuracy * 100.0))
{{if .Classifier.Logistic }}
roc = metrics.roc_auc_score(testLabels, preds)
cr = metrics.classification_report(testLabels, preds)
print("ROC: %.2f%%" % (roc * 100.0))
print(cr)
{{ end }}

# save the model
gbm.save_model('{{ .ModelAbsPath }}')
print('model saved to {{ .ModelAbsPath }}')
{{ end }}