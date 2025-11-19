import torch
from torchvision.models import resnet18, ResNet18_Weights


def main() -> None:
    # Load pretrained ResNet18 with ImageNet weights
    weights = ResNet18_Weights.DEFAULT
    model = resnet18(weights=weights)
    model.eval()

    # Convert to TorchScript
    scripted_model = torch.jit.script(model)

    # Save TorchScript model
    scripted_model.save("model.pt")
    print("✅ TorchScript model saved to model.pt")


if __name__ == "__main__":
    main()
