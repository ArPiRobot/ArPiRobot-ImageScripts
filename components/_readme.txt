Components are shell scripts that perform steps necessary to achieve a single 
goal during OS image configuration. These scripts may need additional resources
which can be placed in a directory next to the script by the same name (without
the .sh extension).

Sometimes, achieving a specific goal is OS / target board dependant. In These
cases, it is recommended that all scripts that achieve the same goal share the
same base name, but prefix the config (../configs) they are designed for. For
example, hwconfig scripts are board specific and are thus named rpi_hwconfig,
opi3b_hwconfig, etc

In other cases, the core functionality to achieve a goal may be similar on all
platforms, but there may be board specific additions required. In these cases,
there can be a base script that performs the common steps and a config specific
script to handle board specific parts. Both would be treated as separate
components that would be added to the relevant configs. For example, the 
readonly component (to make readonly capable FS) is similar across all boards
but some boards may require additional changes to support this. In this case
the readonly component handles the shared / common parts and the rpi_readonly,
opi3b_readonly, etc scripts handle board specific additions / tweaks.