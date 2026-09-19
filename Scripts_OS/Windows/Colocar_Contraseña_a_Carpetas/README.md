# Colocar_Contraseña_a_Carpetas — versión única

## Contenido (canónico, dentro del repositorio)

- `Carpeta_Con_Contrasena.bat`: oculta/muestra la carpeta `CarpetaProtegida`
  con contraseña configurable en la variable `PASSWORD` (inicio del script).

## Uso

1. **Configura tu contraseña**: abre `Carpeta_Con_Contrasena.bat` con el
   Bloc de notas y cambia `set "PASSWORD=CAMBIA_ESTA_CONTRASENA"` por la
   tuya (admite espacios).
2. **Copia el `.bat`** a la carpeta donde quieras tu carpeta protegida
   (la crea en el directorio actual) y haz doble clic.
3. **Primera ejecución**: crea `CarpetaProtegida`. Mete ahí tus archivos.
4. **Bloquear**: ejecuta de nuevo → responde `S` (o `Y`) → la carpeta se
   oculta (queda como `Control Panel.{...}` invisible).
5. **Desbloquear**: ejecuta → escribe tu contraseña → la carpeta reaparece.
6. Idioma inglés: `Carpeta_Con_Contrasena.bat en` (o automático si tu
   Windows está en inglés).

### Si algo falla

- `Contraseña invalida` → revisa que `PASSWORD` no tenga espacios
  accidentales alrededor del `=`.
- Si borraste el `.bat` y la carpeta quedó oculta: crea un `.bat` nuevo
  con la misma contraseña en la misma carpeta y desbloquea.

## Advertencia de seguridad

Esto es **ofuscación, no cifrado**: renombra la carpeta con el CLSID
`Control Panel.{21EC2020-3AEA-1069-A2DD-08002B30309D}` y le aplica atributos
oculto+sistema. Cualquiera con conocimientos básicos puede revertirlo y la
contraseña queda en texto plano dentro del script. **No usar para datos
sensibles.**

## Idiomas (es/en)

- `lang_es.bat` / `lang_en.bat`: 8 claves (`MSG_CONFIRM`, `MSG_INVALID`,
  `MSG_LOCKED`, `MSG_NOTLOCKED`, `MSG_ASKPASS`, `MSG_UNLOCKED`,
  `MSG_BADPASS`, `MSG_CREATED`).
- Detección: parámetro `es|en` > cultura del sistema (`Get-Culture`) >
  español por defecto. Ej.: `Carpeta_Con_Contrasena.bat en`.
- Teclas aceptadas en ambos idiomas: `S/s/Y/y` (sí), `N/n` (no).

## Cambios respecto a las versiones anteriores

- Unificadas las 2 variantes (solo diferían en la contraseña hardcodeada).
- Contraseña parametrizada (`set "PASSWORD=..."`) y comparación entrecomillada
  (admite espacios).
