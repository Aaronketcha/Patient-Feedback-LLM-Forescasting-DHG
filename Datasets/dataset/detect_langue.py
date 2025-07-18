import fasttext
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
from huggingface_hub import hf_hub_download
import numpy as np
import matplotlib.pyplot as plt

# Vérifier le support GPU
print("GPU disponible :", torch.cuda.is_available())
if torch.cuda.is_available():
    print("Nom du GPU :", torch.cuda.get_device_name(0))

# Charger le modèle FastText
model_path = hf_hub_download(repo_id="cis-lmu/glotlid", filename="model.bin")
fasttext_model = fasttext.load_model(model_path)

# Créer la matrice d'embeddings
vocab = fasttext_model.words
embedding_dim = fasttext_model.get_dimension()
embedding_matrix = np.zeros((len(vocab), embedding_dim))
for i, word in enumerate(vocab):
    embedding_matrix[i] = fasttext_model.get_word_vector(word)
embedding_matrix = torch.FloatTensor(embedding_matrix)

# Définir le modèle PyTorch
class TextClassifier(nn.Module):
    def __init__(self, vocab_size, embedding_dim, hidden_dim, output_dim):
        super(TextClassifier, self).__init__()
        self.embedding = nn.Embedding(vocab_size, embedding_dim)
        self.embedding.weight = nn.Parameter(embedding_matrix, requires_grad=True)
        self.fc1 = nn.Linear(embedding_dim, hidden_dim)
        self.fc2 = nn.Linear(hidden_dim, output_dim)
        self.relu = nn.ReLU()

    def forward(self, x):
        embedded = self.embedding(x)
        embedded = embedded.mean(dim=1)
        hidden = self.relu(self.fc1(embedded))
        output = self.fc2(hidden)
        return output

# Dataset
class TextDataset(Dataset):
    def __init__(self, texts, labels, vocab):
        self.texts = texts
        self.labels = labels
        self.vocab = vocab
        self.word2idx = {word: idx for idx, word in enumerate(vocab)}

    def __len__(self):
        return len(self.texts)

    def __getitem__(self, idx):
        text = self.texts[idx]
        label = self.labels[idx]
        indices = [self.word2idx.get(word, 0) for word in text.split()]
        return torch.tensor(indices, dtype=torch.long), torch.tensor(label, dtype=torch.long)

# Fonction personnalisée pour collationner les données
def collate_fn(batch):
    texts, labels = zip(*batch)
    max_len = max(len(text) for text in texts)
    padded_texts = [list(text) + [0] * (max_len - len(text)) for text in texts]
    padded_texts = torch.tensor(padded_texts, dtype=torch.long)
    labels = torch.tensor(labels, dtype=torch.long)
    return padded_texts, labels

# Données d'exemple pour 5 langues
texts = [
    # Anglais
    "hello world",
    "this is a test",
    "good morning everyone",
    # Français
    "bonjour le monde",
    "ceci est un test",
    "bon matin à tous",
    # Duala
    "molo o boso",
    "di nde esango",
    "mbote na bandu bonso",
    # Bassa
    "mbote nyu",
    "i nde ngondo",
    "nyu bwele hilolongo",
    # Ewondo
    "mbolo abui",
    "dzé é nkoé",
    "afan a mvus"
]
labels = [
    0, 0, 0,  # Anglais
    1, 1, 1,  # Français
    2, 2, 2,  # Duala
    3, 3, 3,  # Bassa
    4, 4, 4   # Ewondo
]
dataset = TextDataset(texts, labels, vocab)
dataloader = DataLoader(dataset, batch_size=2, shuffle=True, collate_fn=collate_fn)

# Instancier le modèle
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = TextClassifier(len(vocab), embedding_dim, 128, 5).to(device)  # 5 classes
embedding_matrix = embedding_matrix.to(device)

# Entraînement
criterion = nn.CrossEntropyLoss()
optimizer = optim.Adam(model.parameters(), lr=0.001)
num_epochs = 10
losses = []
for epoch in range(num_epochs):
    model.train()
    total_loss = 0
    for inputs, labels in dataloader:
        inputs, labels = inputs.to(device), labels.to(device)
        optimizer.zero_grad()
        outputs = model(inputs)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()
        total_loss += loss.item()
    avg_loss = total_loss / len(dataloader)
    losses.append(avg_loss)
    print(f"Époque {epoch+1}/{num_epochs}, Perte: {avg_loss:.4f}")

# Sauvegarder le modèle
torch.save(model.state_dict(), "text_classifier.pth")

# Fonction pour prédire sur un texte
def predict(text, model, vocab, word2idx, device):
    model.eval()
    indices = [word2idx.get(word, 0) for word in text.split()]
    input_tensor = torch.tensor([indices], dtype=torch.long).to(device)
    with torch.no_grad():
        output = model(input_tensor)
        _, predicted_class = torch.max(output, dim=1)
    return predicted_class.item()

# Définir le mappage des classes aux langues
class_to_lang = {0: "anglais", 1: "français", 2: "duala", 3: "bassa", 4: "ewondo"}

# Entrée utilisateur pour prédire la langue
word2idx = {word: idx for idx, word in enumerate(vocab)}
while True:
    new_text = input("Entrez un texte pour prédire la langue (ou 'quitter' pour arrêter) : ")
    if new_text.lower() == 'quitter':
        break
    if new_text.strip():
        predicted_class = predict(new_text, model, vocab, word2idx, device)
        predicted_lang = class_to_lang[predicted_class]
        print(f"Le texte '{new_text}' est en : {predicted_lang}")
    else:
        print("Veuillez entrer un texte non vide.")

# Visualiser les pertes
plt.plot(range(1, num_epochs + 1), losses)
plt.xlabel("Époque")
plt.ylabel("Perte")
plt.title("Courbe de perte pendant l'entraînement")
plt.show()