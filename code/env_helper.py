import os
from dotenv import load_dotenv as load_dotenv_base # type: ignore

current_dir = os.path.dirname(os.path.abspath(__file__))
env_path = "../.env"
env_path = os.path.join(current_dir, env_path)
dotenv_loaded = False


def load_dotenv():
    global dotenv_loaded
    if not dotenv_loaded and os.path.exists(env_path):
        load_dotenv_base(env_path)
        dotenv_loaded = True


def get_env_var(key, default=None, allow_empty=False):
    value = os.getenv(key)
    if not value:
        load_dotenv()
        value = os.getenv(key)
    if not value:
        value = default
    if not value:
        if not allow_empty:
            raise ValueError(f"Environment variable {key} not found.")
        return None
    return value
