Import("env")
from pathlib import Path

env_path = Path(env.subst("$PROJECT_DIR")) / ".env"
if not env_path.exists():
    print("[load_env] .env no encontrado, se usaran valores por defecto")
    exit()

header = "#ifndef SECRETS_H\n#define SECRETS_H\n\n"
with open(env_path) as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip()
        if key == "MQTT_BROKER_PORT":
            header += f"#define {key} {value}\n"
        else:
            header += f'#define {key} "{value}"\n'
header += "\n#endif\n"

header_path = Path(env.subst("$PROJECT_DIR")) / "include" / "secrets.h"
with open(header_path, "w") as f:
    f.write(header)

print(f"[load_env] include/secrets.h generado desde .env")
