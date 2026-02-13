import pandas as pd
from datasets import Dataset
from transformers import AutoTokenizer, AutoModelForSequenceClassification, TrainingArguments, Trainer
from sklearn.model_selection import train_test_split

# ---------- FUNCTION TO PREPARE DATA ----------
def prepare_dataset(df):
    train_df, test_df = train_test_split(df, test_size=0.2, random_state=42)
    train_dataset = Dataset.from_pandas(train_df)
    test_dataset = Dataset.from_pandas(test_df)

    def tokenize(example):
        return tokenizer(example["text"], padding="max_length", truncation=True, max_length=128)

    train_dataset = train_dataset.map(tokenize, batched=True)
    test_dataset = test_dataset.map(tokenize, batched=True)

    train_dataset.set_format("torch", columns=["input_ids", "attention_mask", "label"])
    test_dataset.set_format("torch", columns=["input_ids", "attention_mask", "label"])

    return train_dataset, test_dataset

# ---------- LOAD MODEL ----------
model_name = "google/mobilebert-uncased"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForSequenceClassification.from_pretrained(model_name, num_labels=2)

# ---------- PHASE 1 DATA (Disaster dataset) ----------
messages = pd.read_csv("./archive/disaster_messages.csv")
categories = pd.read_csv("./archive/disaster_categories.csv")
df = messages.merge(categories, on="id")

categories = df["categories"].str.split(";", expand=True)
row = df["categories"][0]
category_colnames = [x.split("-")[0] for x in row.split(";")]
categories.columns = category_colnames

for column in categories:
    categories[column] = categories[column].str[-1].astype(int)

df = df.drop("categories", axis=1)
df = pd.concat([df, categories], axis=1)

df1 = df[["message", "aid_related"]]
df1.columns = ["text", "label"]

train_dataset, test_dataset = prepare_dataset(df1)

training_args = TrainingArguments(
    output_dir="./model_phase1",
    per_device_train_batch_size=16,
    per_device_eval_batch_size=16,
    num_train_epochs=2,
    do_train=True,
    do_eval=True
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=test_dataset
)

print("Starting Phase 1 training...")
trainer.train()

model.save_pretrained("model_phase1")
tokenizer.save_pretrained("model_phase1")

# ---------- PHASE 2 DATA (Your custom dataset) ----------
print("Starting Phase 2 training...")

df2 = pd.read_csv("distress_dataset_large_v1.csv")
df2 = df2[["text", "label"]]

train_dataset2, test_dataset2 = prepare_dataset(df2)

# Load previous model
model = AutoModelForSequenceClassification.from_pretrained("model_phase1")

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset2,
    eval_dataset=test_dataset2
)

trainer.train()

model.save_pretrained("mobilebert_distress_final")
tokenizer.save_pretrained("mobilebert_distress_final")

print("Training complete. Final model ready.")
