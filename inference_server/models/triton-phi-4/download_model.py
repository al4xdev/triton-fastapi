from huggingface_hub import snapshot_download
import os


model_id = "microsoft/Phi-4-reasoning-Plus-onnx"
subfolder_to_download = "gpu"
local_dir = "."

print(f"Starting download of subfolder: {subfolder_to_download} from model: {model_id}")

try:
    snapshot_download(
        repo_id=model_id,
        allow_patterns=[f"{subfolder_to_download}/*"],
        local_dir=local_dir,
        local_dir_use_symlinks=False,
    )

    print(f"\nSuccessfully downloaded the '{subfolder_to_download}' subfolder to: {os.path.abspath(local_dir)}")
    print("Download complete!")

except Exception as e:
    print(f"An error occurred during download: {e}")

