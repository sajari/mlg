{{ define "xgb_regressor" }}
import xgboost as xgb
import pandas as pd
import sklearn.metrics as metrics

CSV_COLUMN_NAMES = [{{ .Features.QuotedVars }}, "{{ pascalCase .Regressor.Name }}"]
TRAIN_PATH = '{{ .TrainPath }}'
TEST_PATH = '{{ .TestPath }}'

trainData = pd.read_csv(TRAIN_PATH, header=None, names=CSV_COLUMN_NAMES)
testData  = pd.read_csv(TEST_PATH, header=None, names=CSV_COLUMN_NAMES)

trainLabels = trainData.pop('{{ pascalCase .Regressor.Name }}')
testLabels = testData.pop('{{ pascalCase .Regressor.Name }}')

# train the model
gbm = xgb.XGBRegressor(
        {{ range $k, $v := .Model.Config }}{{ $k }} = {{ printf "%#v" $v }}, 
        {{ end }}).fit(trainData, trainLabels)

# make prediction
preds = gbm.predict(testData)

accuracy = metrics.r2_score(testLabels, preds)
print("R2: %.2f%%" % (accuracy * 100.0))

evs = metrics.explained_variance_score(testLabels, preds)
print("Explained Variance Score: %.2f%%" % (evs * 100.0))

mae = metrics.mean_absolute_error(testLabels, preds)
print("Mean Absolute Error: %.2f%%" % (mae * 100.0))

# save the model
gbm.save_model('{{ .ModelAbsPath }}')

{{ end }}