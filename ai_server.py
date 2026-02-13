from flask import Flask, request, jsonify
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch

app = Flask(__name__)

model_path = "mobilebert_distress_final"
tokenizer = AutoTokenizer.from_pretrained(model_path)
model = AutoModelForSequenceClassification.from_pretrained(model_path)

def predict(text):
    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True)
    outputs = model(**inputs)
    probs = torch.softmax(outputs.logits, dim=1)
    pred = torch.argmax(probs, dim=1).item()
    return pred

@app.route("/check_distress", methods=["POST"])
def check_distress():
    text = request.json["text"]
    result = predict(text)

    label = "DISTRESS" if result == 1 else "NORMAL"
    print(f"Text: {text} → {label}")

    return jsonify({"result": label})

app.run(host="0.0.0.0", port=5000)
