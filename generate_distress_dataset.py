import random
import pandas as pd

random.seed(42)

distress_phrases = [
    # Core English
    "help me", "please help", "save me", "i am in danger",
    "someone is following me", "i feel unsafe", "they are trying to hurt me",
    "i am trapped", "i cannot escape", "please come fast",
    "call police", "i am scared", "i am not safe here",
    "someone is chasing me", "i am in trouble", "i am stuck here",
    "he is forcing me", "they are attacking me",
    "i need help urgently", "this is emergency help me",

    # Hindi Roman
    "madad karo", "mujhe bachao", "mujhe madad chahiye",
    "koi mera picha kar raha hai", "mujhe dar lag raha hai",
    "mai safe nahi hu", "mai akeli hu aur dar rahi hu",
    "jaldi aao please", "koi mujhe dhakka de raha hai",
    "mujhe dhamki di ja rahi hai", "koi mujhe pakad raha hai",
    "mai fasa hua hu", "mujhe nuksan pahucha rahe hai",

    # Marathi Roman
    "mala madat kara", "mala vachva", "mala bhiti vatate",
    "mi safe nahi ahe", "koni majha pichha kart ahe",
    "mi faslo ahe", "mi adaklo ahe", "lavkar ya please",
    "koni majhya var halla kart ahe", "mi ekaṭi ahe ani ghabarleli ahe"
]

normal_phrases = [
    # English daily
    "i am fine", "everything is okay", "i am safe",
    "i am going to college", "i am coming home",
    "i am studying now", "i am in class",
    "i am talking to my friend", "i am watching a movie",
    "i am feeling relaxed", "i am working on my project",
    "i am having lunch", "i am reading a book",
    "i am going to sleep", "i am walking outside",
    "i am listening to music", "i am at home",

    # Hindi Roman
    "sab theek hai", "mai theek hu", "mai safe hu",
    "mai ghar par hu", "mai market me hu",
    "mai laptop use kar raha hu", "mai bus me hu",
    "koi problem nahi hai", "mai normal feel kar raha hu",

    # Marathi Roman
    "mi thik ahe", "mi safe ahe", "mi ghari ahe",
    "mi college la jat ahe", "mi bus madhe ahe",
    "mi study karat ahe", "sagle barobar ahe",
    "mi mitra sobat bolat ahe"
]

# ASR-style variations (simulated speech mistakes)
def augment(text):
    variations = [
        text,
        text.replace("me", "mi"),
        text.replace("i am", "im"),
        text.replace("please", "pls"),
        text.replace("karo", "kro"),
        text.replace("mujhe", "muje"),
        text.replace("madat", "madat"),
        text + " please",
        "hey " + text,
        text + " help",
    ]
    return random.choice(variations)

data = []

def add_samples(phrases, label, n=400):
    for _ in range(n):
        text = augment(random.choice(phrases))
        data.append([text, label])

# Generate dataset
add_samples(distress_phrases, 1, n=600)  # distress
add_samples(normal_phrases, 0, n=600)    # normal

random.shuffle(data)

df = pd.DataFrame(data, columns=["text","label"])
df.to_csv("distress_dataset_large_v1.csv", index=False)

print("Dataset generated:", len(df), "samples")
print("Saved as distress_dataset_large_v1.csv")

