# La Guía

Todo lo que el [README](../README.es.md) dejó fuera a propósito. 🇬🇧 [English version](GUIDE.md)

- [Cómo está montado](#cómo-está-montado)
- [Los scripts auxiliares](#los-scripts-auxiliares)
- [Referencia de configuración](#referencia-de-configuración)
- [Credenciales](#credenciales)
- [Notas por plataforma (Linux / macOS / WSL2)](#notas-por-plataforma)
- [Decisiones de diseño que conviene conocer](#decisiones-de-diseño-que-conviene-conocer)
- [Resolución de problemas](#resolución-de-problemas)

## Cómo está montado

```
.
├── install.sh                    instalador por symlinks (--dry-run, --uninstall)
├── bin/
│   ├── git-overview              tabla de estado git de una carpeta de repos
│   ├── zj-logs                   visor de logs con descubrimiento y fallbacks
│   ├── zj-cd                     shell en la carpeta de proyectos
│   └── zj-docker                 TUI de Docker con chequeo de accesibilidad
├── zellij/
│   ├── config.kdl                solo lo que difiere de los defaults de Zellij
│   ├── layouts/dev.kdl           el workspace de seis tabs
│   └── themes/debian.kdl         "debian" (acento rojo) y "tango"
├── lazygit/config.yml
├── lazydocker/config.yml
└── lazysql/config.toml.example   plantilla — el archivo real está en .gitignore
```

El instalador enlaza las configs en `$XDG_CONFIG_HOME` (o `~/.config`) y los
cuatro scripts en `~/.local/bin`. Lo que ya exista se mueve a
`<archivo>.backup-<fecha>`, nunca se borra. Volver a ejecutarlo es seguro;
`--uninstall` quita los enlaces y restaura el backup más reciente de cada uno.

### ¿Por qué no `$VAR` directamente en el layout?

Porque el parser KDL de Zellij **no expande variables de entorno** en `cwd` ni
en `args`. Esa es la razón por la que casi todos los layouts publicados acaban
con el `$HOME` de alguien incrustado. Aquí, todo lo que necesita un valor en
tiempo de ejecución va envuelto en `sh -c` (donde el shell sí expande) o
delegado a un script de `bin/`. Los paneles sin `cwd` heredan el directorio
desde el que lanzaste `zellij`.

## Los scripts auxiliares

Los cuatro funcionan por su cuenta, fuera de Zellij.

**`git-overview [dir]`** — tabla con rama, último commit y archivos modificados
de cada repositorio git que cuelgue de `dir`. Lista solo *raíces* de
repositorio, así que sigue siendo correcto aunque la carpeta esté dentro de
otro repo.

**`zj-logs [archivo]`** — abre un log con el mejor visor disponible
(`lnav` → `less +F` → `tail -F`). Sin argumento usa `$ZJ_LOG_FILE`, y si no,
el `*.log` modificado más recientemente bajo la carpeta de proyectos
(profundidad 4). ¿No encuentra nada? Imprime instrucciones y te deja un shell
en lugar de cerrarse.

**`zj-cd [dir]`** — shell interactivo en la carpeta de proyectos.

**`zj-docker`** — comprueba que el demonio de Docker responde antes de lanzar
`lazydocker`, y nombra la causa cuando no. El caso interesante está en
[la trampa del grupo `docker`](#la-trampa-del-grupo-docker).

## Referencia de configuración

| Variable | Por defecto | La usan |
|---|---|---|
| `ZJ_PROJECTS_DIR` | `~/Projects`, si no el directorio actual | tabs `git` y `projects`, `git-overview`, búsqueda de `zj-logs` |
| `ZJ_LOG_FILE` | el `*.log` más reciente bajo `ZJ_PROJECTS_DIR` (prof. 4) | tab `logs` |
| `ZJ_BIN_DIR` | `~/.local/bin` | dónde enlaza los scripts `install.sh` |
| `ZJ_SESSION` | `dev` | sesión a la que se conecta `zdev`, o que crea |
| `ZJ_LAYOUT` | `dev` | layout con el que `zdev` la crea |

En tu perfil de shell, o por invocación:

```bash
ZJ_LOG_FILE=/var/log/syslog zdev
ZJ_SESSION=api zdev            # un segundo workspace, aparte
```

Lanza con `zdev`, no con `zellij --layout dev`. Este último crea siempre una
sesión nueva con nombre aleatorio, y Zellij nunca elimina las que dejas
desconectadas — así que ejecutarlo una vez por terminal te deja un montón de
workspaces vivos que no ves, cada uno con sus paneles todavía corriendo.

## Credenciales

`lazysql/config.toml.example` es una plantilla. El instalador la copia a
`~/.config/lazysql/config.toml` **solo si ese archivo no existe ya**, y el
archivo real está en `.gitignore`, porque lazysql guarda las conexiones como
`proveedor://usuario:contraseña@host:puerto/base` en texto plano.

Se copia, no se enlaza, a propósito: un symlink metería tus contraseñas dentro
del árbol de trabajo del repo, a un `git add -A` de acabar publicadas.

Si alguna vez subes uno por error, rota esas contraseñas. Borrarlo en un commit
posterior no lo elimina del historial de git.

## Notas por plataforma

### Linux 🐧

Primera clase. Desarrollado y probado en Linux (familia Mint/Ubuntu); nada es
específico de una distro — `/etc/os-release`, `getent` y GNU coreutils son las
únicas suposiciones.

### macOS

Funciona casi todo. Los scripts ya llevan fallbacks BSD (`stat -f` en
`zj-logs`) y la nota de portapapeles en `zellij/config.kdl` cubre `pbcopy`.
Instala las herramientas opcionales con Homebrew. No se prueba con
regularidad — se agradecen reportes.

### WSL2 — corre, con obstáculos

Funciona, pero espera fricción. Obstáculos conocidos, en el orden en que te
los encontrarás:

1. **Docker.** No hay `dockerd` dentro de una distro WSL2 recién instalada.
   O activas *Docker Desktop → Settings → Resources → WSL integration* para tu
   distro, o instalas Docker Engine nativo dentro de WSL2 (requiere systemd
   habilitado en `/etc/wsl.conf`). Hasta entonces el tab `docker` diagnosticará
   "no se puede alcanzar el demonio" — y estará en lo cierto.
2. **Portapapeles.** Zellij copia vía OSC 52, que Windows Terminal soporta —
   pero algunos terminales (ConEmu, mintty antiguo) no. Si copiar falla,
   `clip.exe` funciona: `copy_command "clip.exe"` en `config.kdl`.
3. **Fuentes.** Los glifos powerline de la barra necesitan una Nerd Font
   *configurada en Windows Terminal*, no dentro de WSL. O pon
   `simplified_ui true`.
4. **Rendimiento.** Mantén tus repos dentro del sistema de archivos de WSL
   (`~/...`), no bajo `/mnt/c`. El tab `git` relanza `git status` sobre cada
   repo cada 5 segundos, y el acceso 9P lo vuelve dolorosamente lento.

Windows nativo (PowerShell/cmd): no soportado. Los scripts son shell POSIX.

## Decisiones de diseño que conviene conocer

`zellij/config.kdl` es deliberadamente corto. Tres decisiones merecen
explicación, porque cada una es una forma habitual de que un setup de Zellij
acabe pareciendo roto:

- **`session_serialization false`.** Zellij, por defecto, guarda el layout
  vivo en `~/.cache/zellij` y lo resucita en el siguiente arranque. Mientras
  editas layouts, tus cambios en el `.kdl` parecen no surtir efecto: sigues
  recibiendo la sesión antigua, con paneles muertos marcados
  `start_suspended true`. Reactívalo cuando tus layouts estén estables.
- **`default_layout "default"`.** Poner un workspace pesado como layout por
  defecto hace que *cada* terminal nueva levante toda la pila de
  monitorización. Mejor lanzarlo explícitamente (o con el alias `zdev`).
- **Sin bloque `keybinds`.** El plugin de configuración de Zellij vuelca la
  tabla completa de atajos por defecto al guardar: ~250 líneas que no cambian
  nada y entierran las personalizaciones reales. Usa
  `zellij setup --dump-config` para consultar los defaults.

**Un panel por tab** en `monitor`: btop se niega a dibujar por debajo de
80×16, así que compartir una ventana de ~120 columnas lo condena al
"Terminal size too small". Con el tab entero renderiza incluso a 80×24.

### La trampa del grupo `docker`

Los grupos suplementarios se asignan al crear el proceso y no se pueden
añadir a uno en marcha. Si tu sesión arrancó antes de ejecutar
`usermod -aG docker`, todo shell que lance carece del grupo — mientras `id`
te informa tan tranquilo de que eres miembro. Abrir una ventana "nueva" de
terminal tampoco suele servir: las ventanas nuevas se enganchan al mismo
proceso servidor de terminal, que es viejo.

`zj-docker` compara los grupos reales del proceso (`id -G`) con los de la
cuenta (`id -nG`). Cuando solo falta en el proceso, se relanza a través de
`sg docker` — setuid, puede conceder el grupo — lo que normalmente arregla el
panel sin cerrar sesión. Un solo reintento, acotado por una variable guarda;
si aun así falla, imprime las soluciones restantes por orden de contundencia.

## Resolución de problemas

**Mis cambios en el layout no hacen nada.** La serialización de sesiones está
resucitando una sesión antigua. Mira `zellij list-sessions`, luego
`zellij delete-all-sessions` (o bórralas una a una), o vacía `~/.cache/zellij`.

**Hay paneles muertos / suspendidos.** El comando del panel terminó — pulsa
`Enter` dentro para relanzarlo. Si pasa en cada arranque, falta una
herramienta o ruta; todos los paneles de este repo explican el motivo.

**No encuentra los scripts auxiliares.** `~/.local/bin` no está en tu `PATH`.
Añade `export PATH="$HOME/.local/bin:$PATH"` a tu perfil de shell.

**Copiar no llega al portapapeles.** Descomenta la línea `copy_command` que
corresponda en `zellij/config.kdl` (`xclip` en X11, `wl-copy` en Wayland,
`pbcopy` en macOS, `clip.exe` en WSL2).

**Los iconos salen como cuadrados.** Usa una Nerd Font, o pon
`simplified_ui true` en `zellij/config.kdl`.

**lnav arranca con una pared de "Permiso denegado".** Los archivos de
`~/.config/lnav/formats/default/` perdieron el bit de escritura (puede pasar
al migrar configs entre máquinas con `tar`). Arreglo:
`chmod -R u+w ~/.config/lnav` — o borra `formats/default` y
`configs/default`; lnav los regenera.

**Al tab monitor le falta una caja (CPU, mem, net o proc).** btop guarda qué
cajas estaban visibles al salir, en `~/.config/btop/btop.conf`
(`shown_boxes`). Pulsa `1`–`4` dentro de btop para reactivar cpu/mem/net/proc
— el estado persiste al salir. Este repo no incluye config de btop a
propósito: btop reescribe su archivo en cada salida, así que un symlink nunca
se mantendría limpio.

**El tab db muestra conexiones viejas.** lazysql lista lo que haya guardado en
`~/.config/lazysql/config.toml` — ese archivo es tuyo, no del repo. Edítalo
para quitar conexiones cuyos servicios ya no existen.
