{{ define "xgb_ranker" }}
#!/usr/bin/python
import xgboost as xgb
from xgboost import DMatrix
from sklearn.datasets import load_svmlight_file

x_train, y_train = load_svmlight_file('{{ .TrainPath }}')
x_valid, y_valid = load_svmlight_file('{{ .ValidPath }}')
x_test, y_test = load_svmlight_file('{{ .TestPath }}')

group_train = []
with open("{{ .TrainPath }}.group", "r") as f:
    data = f.readlines()
    for line in data:
        group_train.append(int(line.split("\n")[0]))

group_valid = []
with open("{{ .ValidPath }}.group", "r") as f:
    data = f.readlines()
    for line in data:
        group_valid.append(int(line.split("\n")[0]))

group_test = []
with open("{{ .TestPath }}.group", "r") as f:
    data = f.readlines()
    for line in data:
        group_test.append(int(line.split("\n")[0]))

train_dmatrix = DMatrix(x_train, y_train)
valid_dmatrix = DMatrix(x_valid, y_valid)
test_dmatrix = DMatrix(x_test)

train_dmatrix.set_group(group_train)
test_dmatrix.set_group(group_test)

params = {
        {{ range $k, $v := .Config }}{{ printf "%#v" $k }} : {{ printf "%#v" $v }}, 
        {{ end }}
        }
gbm = xgb.train(params, train_dmatrix, 
    evals=[(valid_dmatrix, 'validation')], verbose_eval=1)

# Save
gbm.save_model('{{ .ModelAbsPath }}')

preds = gbm.predict(test_dmatrix)
# Print predictions for the test set
# print("\n".join([str(score) for score in preds])) 

print(gbm.get_score(importance_type='total_gain'))

print("model trained and saved to: {{ .ModelAbsPath }}")
{{ end }}
