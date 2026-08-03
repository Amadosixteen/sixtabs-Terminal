# zellij-config

Un espacio de trabajo portable para [Zellij](https://zellij.dev), más la
configuración correspondiente de `lazygit`, `lazydocker` y `lazysql`. Sin rutas
absolutas, sin directorios personales y sin credenciales: clónalo en cualquier
máquina Linux o macOS y funciona, o degrada con un mensaje claro en vez de
dejarte un panel muerto.

> 🇬🇧 English documentation: [README.md](README.md)

```
zellij --layout dev
```

## Qué incluye

| Tab | Contenido | Alternativas si falta la herramienta |
|---|---|---|
| `monitor` | CPU, memoria, discos, red, procesos | `btop` → `htop` → `top` |
| `docker` | gestión interactiva de contenedores | `lazydocker` → `docker stats` → shell, con diagnóstico si el demonio no responde |
| `db` | cliente TUI de bases de datos | `lazysql` → shell indicando cómo instalarlo |
| `logs` | sigue un log de aplicación | `lnav` → `less +F` → `tail -F` |
| `git` | estado en una línea de cada repo de tu carpeta de proyectos, más un shell | shell |
| `projects` | shell libre en tu carpeta de proyectos | directorio actual |

## Requisitos

Solo **Zellij** es obligatorio. Todo lo demás es opcional: cada panel comprueba
su herramienta y se explica si no está.

```bash
cargo install --locked zellij
# o: brew install zellij  /  pacman -S zellij  /  binario desde releases
```

Opcionales, por utilidad aproximada:
[`btop`](https://github.com/aristocratos/btop),
[`lazygit`](https://github.com/jesseduffield/lazygit),
[`lazydocker`](https://github.com/jesseduffield/lazydocker),
[`lnav`](https://lnav.org),
[`lazysql`](https://github.com/jorgerojas26/lazysql),
[`fastfetch`](https://github.com/fastfetch-cli/fastfetch).

## Instalación

```bash
git clone https://github.com/<tu-usuario>/zellij-config.git
cd zellij-config
./install.sh --dry-run     # muestra qué haría, sin tocar nada
./install.sh
```

El instalador crea enlaces simbólicos en `$XDG_CONFIG_HOME` (o `~/.config`) y
coloca cuatro scripts en `~/.local/bin`. Lo que ya existiera se **mueve a
`<archivo>.backup-<fecha>`**, nunca se borra. Volver a ejecutarlo es seguro.

`./install.sh --uninstall` quita los enlaces y restaura el backup más reciente.

## Configuración

Todo se controla con dos variables de entorno opcionales.

| Variable | Valor por defecto | La usan |
|---|---|---|
| `ZJ_PROJECTS_DIR` | `~/Projects`, si no el directorio actual | tabs `git` y `projects`, `git-overview` |
| `ZJ_LOG_FILE` | el `*.log` más reciente bajo `ZJ_PROJECTS_DIR` (profundidad 4) | tab `logs` |

```bash
export ZJ_PROJECTS_DIR="$HOME/code"
ZJ_LOG_FILE=/var/log/syslog zellij --layout dev
```

Si no defines ninguna, los paneles heredan el directorio desde el que lanzaste
`zellij`. Es decir, `cd ~/mi-proyecto && zellij --layout dev` hace lo esperable
sin configurar nada.

### ¿Por qué no `$VAR` directamente en el layout?

Porque el parser KDL de Zellij **no expande variables de entorno** en `cwd` ni
en `args`. Esa es justamente la razón por la que casi todos los layouts que
circulan por internet acaban con el `$HOME` de alguien incrustado. Aquí, todo lo
que necesita un valor en tiempo de ejecución va envuelto en `sh -c` (donde el
shell sí expande) o delegado a un script de `bin/`. Los paneles sin `cwd`
heredan el directorio de la sesión.

## Scripts auxiliares

Los cuatro funcionan por su cuenta, fuera de Zellij.

- **`git-overview [dir]`** — tabla con rama, último commit y número de archivos
  modificados de cada repositorio git que cuelgue de `dir`. Lista solo *raíces*
  de repositorio, así que sigue siendo correcto aunque la carpeta esté dentro de
  otro repo.
- **`zj-logs [archivo]`** — abre un log con el mejor visor disponible. Sin
  argumento usa `$ZJ_LOG_FILE`, y si no, el `*.log` modificado más
  recientemente. Si no encuentra nada, imprime instrucciones y te deja un shell
  en lugar de cerrarse.
- **`zj-cd [dir]`** — abre un shell interactivo en la carpeta de proyectos.
- **`zj-docker`** — comprueba que el demonio de Docker es realmente accesible
  antes de lanzar `lazydocker`, y nombra la causa cuando no lo es. Distingue
  *la cuenta no está en el grupo `docker`* del caso mucho más confuso en el que
  la cuenta **sí** está pero el proceso en ejecución no.

### La trampa del grupo `docker`

Los grupos suplementarios se asignan al crear el proceso y no se pueden añadir a
uno en marcha. Si tu sesión arrancó antes de ejecutar `usermod -aG docker`, todo
lo que lance esa sesión carece del grupo, mientras `id` te informa tan tranquilo
de que sí eres miembro. Abrir una terminal "nueva" tampoco suele servir: las
ventanas nuevas se enganchan al mismo proceso servidor de terminal, que es viejo.

`zj-docker` compara los grupos reales del proceso (`id -G`) con los de la cuenta
(`id -nG`) y te dice en cuál de los dos casos estás. La solución es cerrar sesión
y volver a entrar, `pkill gnome-terminal-server`, o `newgrp docker` para un shell.

## Credenciales

`lazysql/config.toml.example` es una plantilla. El instalador la copia a
`~/.config/lazysql/config.toml` **solo si ese archivo no existe ya**, y el
archivo real está en `.gitignore`, porque lazysql guarda las conexiones como
`proveedor://usuario:contraseña@host:puerto/base` en texto plano.

Se copia, no se enlaza, a propósito: un symlink metería tus contraseñas dentro
del árbol de trabajo del repo, a un `git add -A` de acabar publicadas.

Si alguna vez subes uno por error, rota esas contraseñas. Borrar el archivo en
un commit posterior no lo elimina del historial de git.

## Notas sobre la config de Zellij

`zellij/config.kdl` es deliberadamente corto. Tres decisiones merecen
explicación, porque cada una es una forma habitual de que un setup de Zellij
acabe pareciendo roto:

- **`session_serialization false`.** Zellij, por defecto, guarda el layout vivo
  en `~/.cache/zellij` y lo resucita en el siguiente arranque. Mientras editas
  layouts, eso hace que tus cambios en el `.kdl` parezcan no surtir efecto:
  sigues recibiendo la sesión antigua, con los paneles de comando muertos
  marcados como `start_suspended true`. Vuelve a activarlo cuando tus layouts
  estén estables.
- **`default_layout "default"`.** Poner un workspace pesado como layout por
  defecto hace que *cada* terminal nueva levante toda la pila de monitorización:
  fácilmente ocho procesos extra por sesión. Mejor lanzarlo a mano con
  `zellij --layout dev`.
- **Sin bloque `keybinds`.** El plugin de configuración de Zellij vuelca la
  tabla completa de atajos por defecto en tu config al guardar: unas 250 líneas
  que no cambian nada y que entierran cualquier personalización real. Usa
  `zellij setup --dump-config` para consultar los valores por defecto, y añade
  aquí un bloque `keybinds` solo para lo que de verdad modifiques.

## Resolución de problemas

**Mis cambios en el layout no hacen nada.** La serialización de sesiones está
resucitando una sesión antigua. Compruébalo con `zellij list-sessions` y luego
`zellij delete-all-sessions`, o vacía `~/.cache/zellij`.

**Hay paneles muertos o suspendidos.** El comando del panel terminó. Pulsa
`Enter` dentro para relanzarlo. Si pasa en cada arranque, falta el comando o una
ruta que necesita: todos los paneles de este repo explican el motivo.

**No encuentra los scripts auxiliares.** `~/.local/bin` no está en tu `PATH`.
Añade `export PATH="$HOME/.local/bin:$PATH"` a tu perfil de shell.

**Copiar no llega al portapapeles del sistema.** Zellij usa OSC 52 por defecto y
algunas terminales no lo soportan. Descomenta la línea `copy_command` que
corresponda en `zellij/config.kdl` (`xclip` para X11, `wl-copy` para Wayland,
`pbcopy` para macOS).

**Los iconos salen como cuadrados.** Pon `simplified_ui true` en
`zellij/config.kdl`, o usa una Nerd Font.

## Estructura

```
.
├── install.sh                    instalador por symlinks (--dry-run, --uninstall)
├── bin/
│   ├── git-overview              tabla de estado git de una carpeta de repos
│   ├── zj-logs                   visor de logs con descubrimiento y fallbacks
│   ├── zj-cd                     shell en la carpeta de proyectos
│   └── zj-docker                 TUI de Docker con chequeo de accesibilidad
├── zellij/
│   ├── config.kdl                solo lo que difiere de los valores por defecto
│   ├── layouts/dev.kdl           el workspace de seis tabs
│   └── themes/debian.kdl         "debian" (acento rojo) y "tango"
├── lazygit/config.yml
├── lazydocker/config.yml
└── lazysql/config.toml.example   plantilla — el archivo real está en .gitignore
```

## Licencia

MIT — ver [LICENSE](LICENSE).
