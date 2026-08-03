<div align="center">

# zellij-config

**Todo tu entorno de desarrollo. Un comando. Cero configuración.**

[![Licencia: MIT](https://img.shields.io/badge/licencia-MIT-2ea44f)](LICENSE)
[![Plataforma: Linux](https://img.shields.io/badge/plataforma-Linux-1793d1)](#-linux-primero)
[![Hecho con: Zellij](https://img.shields.io/badge/hecho%20con-Zellij-d70a53)](https://zellij.dev)

🇬🇧 [Read it in English](README.md)

</div>

---

Conoces el ritual. Una terminal para los contenedores. Otra siguiendo un log.
Una tercera para `git status`, otra vez. La cuarta... ¿dónde estaba la cuarta?

Este repo reemplaza el ritual con una tecla:

```
zellij --layout dev
```

```
┃ monitor ┃ docker ┃ db ┃ logs ┃ git ┃ projects ┃
```

Seis tabs. Todo ya en marcha, ya apuntando a tu trabajo:

|   | Tab | Lo que te espera |
|---|-----|------------------|
| 📈 | **monitor** | CPU, memoria, discos, red, procesos — en vivo |
| 🐳 | **docker** | Cada contenedor: logs, restart, shell dentro, stats |
| 🗄️ | **db** | Tus bases de datos en un cliente TUI completo |
| 📜 | **logs** | El log de tu app, en streaming, con búsqueda |
| 🌿 | **git** | Rama y cambios de cada repo, refrescado cada 5s |
| 🚀 | **projects** | Un shell, ya dentro de tu carpeta de código |

Sin rutas absolutas. Sin proyectos incrustados. Sin credenciales.
Clónalo en cualquier máquina Linux y simplemente... encaja.

## Consíguelo

```bash
git clone https://github.com/TU_USUARIO/zellij-config.git
cd zellij-config
./install.sh
```

Ese es todo el setup. Prueba antes con `./install.sh --dry-run` si prefieres
mirar antes de tocar — y todo lo que reemplaza queda respaldado, nunca borrado.
`./install.sh --uninstall` lo devuelve a como estaba.

Solo [Zellij](https://zellij.dev) es obligatorio. El resto es opcional:

> btop · lazydocker · lazysql · lnav · lazygit

¿Falta alguno? El panel te dice qué haría, cómo instalarlo, y te deja un shell
funcional en su lugar. **Aquí nada muere en silencio** — esa es la regla de
diseño sobre la que está construido todo el repo. Hasta la clásica trampa de
*"docker funciona con root pero no conmigo"* se detecta, se explica, y en la
mayoría de los casos se arregla sola.

## Hazlo tuyo

Dos variables opcionales. Esa es toda la superficie de configuración:

```bash
export ZJ_PROJECTS_DIR="$HOME/code"     # donde viven tus repos
export ZJ_LOG_FILE="/ruta/a/tu/app.log" # un log concreto a seguir
```

Si no defines ninguna, encuentra `~/Projects` y tu log más reciente por su cuenta.

## 🐧 Linux primero

Construido en Linux, probado en Linux. En macOS casi todo funciona. **WSL2 lo
corre con obstáculos** (socket de Docker, portapapeles, fuentes) — documentados
con honestidad, no barridos bajo la alfombra. Windows nativo: no.

Los detalles y la resolución de problemas viven en la
**[Guía](docs/GUIA.es.md)**.

---

<div align="center">

MIT — tómalo, rómpelo, hazlo tuyo.

</div>
