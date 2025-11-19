import sys
from pathlib import Path

import torch
from PIL import Image
from torchvision import transforms
from torchvision.models import ResNet18_Weights

MODEL_PATH = "model.pt"
model = torch.jit.load(MODEL_PATH, map_location="cpu")
model.eval()

weights = ResNet18_Weights.DEFAULT
preprocess = weights.transforms()
labels = weights.meta["categories"]


def predict(image_path: str, top_k: int = 3) -> None:
    """
    Run inference on a single image and print top-k predictions:
    class index, class name and probability.
    """
    img_path = Path(image_path)
    if not img_path.exists():
        raise FileNotFoundError(f"Image not found: {img_path}")

    image = Image.open(img_path).convert("RGB")
    input_tensor = preprocess(image).unsqueeze(0)  

    with torch.no_grad():
        outputs = model(input_tensor)  
        probs = torch.softmax(outputs[0], dim=0)

    top_probs, top_indices = torch.topk(probs, k=top_k)

    print(f"Image: {img_path}")
    print(f"Top-{top_k} predictions:")
    for rank, (p, idx) in enumerate(zip(top_probs, top_indices), start=1):
        class_id = idx.item()
        class_name = labels[class_id]
        print(f"{rank}. id={class_id:3d} | {class_name:25s} | prob={p.item():.4f}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python inference.py <image_path>")
        sys.exit(1)

    predict(sys.argv[1], top_k=3)
